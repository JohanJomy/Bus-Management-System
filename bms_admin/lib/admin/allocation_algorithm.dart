import 'dart:collection';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Bottom-Up Greedy Flow allocation for bus manifests.
///
/// Usage:
/// - Create [BottomUpGreedyFlowAllocator]
/// - Call [allocateForDate] with target date, active semesters, and active courses.
/// - Read [AllocationRunResult.insertStatements] and [AllocationRunResult.summaryReport]
/// - Optionally set [persistToDatabase] to true to write into `daily_manifests`.
class BottomUpGreedyFlowAllocator {
	BottomUpGreedyFlowAllocator({SupabaseClient? client})
			: _client = client ?? Supabase.instance.client;

	final SupabaseClient _client;

	Future<AllocationRunResult> allocateForDate({
		required DateTime targetDate,
		required List<int> activeSemesters,
		required List<String> activeCourses,
		bool persistToDatabase = false,
		int rootStopId = 235,
		bool clearAllExistingManifests = false,
		bool requirePaidStudents = false,
		bool includeStaffWithoutSemester = true,
	}) async {
		if (activeSemesters.isEmpty) {
			throw Exception('activeSemesters cannot be empty.');
		}
		// activeCourses may be empty when caller wants all courses + staff.

		final dateIso = _toDateOnly(targetDate);

		final busesRaw = await _client
				.from('buses')
				.select('id,bus_number,total_capacity') as List<dynamic>;

		if (busesRaw.isEmpty) {
			throw Exception('No buses found in database.');
		}

		final stopRaw = await _client.from('stops').select('id,actual_bus')
				as List<dynamic>;
		final linksRaw = await _client
				.from('stop_links')
				.select('from_stop_id,to_stop_id') as List<dynamic>;

		final studentsRaw = <Map<String, dynamic>>[];
		const pageSize = 1000;
		var from = 0;
		while (true) {
			final page = await _client
					.from('students')
					.select('id,full_name,course,semester,boarding_stop_id')
					.not('boarding_stop_id', 'is', null)
					.range(from, from + pageSize - 1) as List<dynamic>;
			final rows = page.cast<Map<String, dynamic>>();
			if (rows.isEmpty) break;
			studentsRaw.addAll(rows);
			if (rows.length < pageSize) break;
			from += pageSize;
		}

		final paymentsRaw = <Map<String, dynamic>>[];
		if (requirePaidStudents) {
			var paymentFrom = 0;
			while (true) {
				final page = await _client
						.from('payments')
						.select('student_id,semester,status')
						.eq('status', true)
						.inFilter('semester', activeSemesters)
						.range(paymentFrom, paymentFrom + pageSize - 1) as List<dynamic>;
				final rows = page.cast<Map<String, dynamic>>();
				if (rows.isEmpty) break;
				paymentsRaw.addAll(rows);
				if (rows.length < pageSize) break;
				paymentFrom += pageSize;
			}
		}

		final buses = busesRaw
				.map((e) => _BusState.fromMap(e as Map<String, dynamic>))
				.toList();
		final stopNodes = {
			for (final row in stopRaw)
				(row as Map<String, dynamic>)['id'] as int:
						_StopNode.fromMap(row),
		};

		final paidSemestersByStudent = <String, Set<int>>{};
		if (requirePaidStudents) {
			for (final row in paymentsRaw) {
				final studentId = row['student_id']?.toString();
				final semester = _toInt(row['semester']);
				final status = row['status'] == true;
				if (studentId == null || semester == null || !status) continue;
				paidSemestersByStudent.putIfAbsent(studentId, () => <int>{}).add(semester);
			}
		}

		final courseSet = activeCourses.map((e) => e.trim().toLowerCase()).toSet();
		final eligibleStudents = <_StudentNode>[];
		var staffAllocatedCount = 0;
		for (final row in studentsRaw) {
			final student = _StudentNode.fromMap(row);
			if (student.boardingStopId == null) continue;

			final semester = student.semester;
			final normalizedCourse = (student.course ?? '').trim().toLowerCase();

			if (semester == null) {
				if (includeStaffWithoutSemester) {
					eligibleStudents.add(student);
					staffAllocatedCount += 1;
				}
				continue;
			}

			if (!activeSemesters.contains(semester)) {
				continue;
			}
			if (courseSet.isNotEmpty && !courseSet.contains(normalizedCourse)) {
				continue;
			}

			if (!requirePaidStudents) {
				eligibleStudents.add(student);
				continue;
			}
			final paidSemesters = paidSemestersByStudent[student.id] ?? const <int>{};
			if (paidSemesters.contains(student.semester)) {
				eligibleStudents.add(student);
			}
		}

		final studentsByStop = <int, Queue<_StudentNode>>{};
		eligibleStudents.sort((a, b) {
			final aStop = a.boardingStopId ?? -1;
			final bStop = b.boardingStopId ?? -1;
			if (aStop != bStop) return aStop.compareTo(bStop);
			return a.id.compareTo(b.id);
		});
		for (final student in eligibleStudents) {
			final stopId = student.boardingStopId!;
			studentsByStop.putIfAbsent(stopId, Queue.new).add(student);
			stopNodes.putIfAbsent(stopId, () => _StopNode(id: stopId, actualBusId: null));
		}

		// Build undirected graph from stop_links; then root it at [rootStopId]
		// so traversal can run bottom-up from leaves to root.
		final undirected = <int, Set<int>>{
			for (final id in stopNodes.keys) id: <int>{},
		};

		for (final row in linksRaw.cast<Map<String, dynamic>>()) {
			final from = _toInt(row['from_stop_id']);
			final to = _toInt(row['to_stop_id']);
			if (from == null || to == null) continue;

			stopNodes.putIfAbsent(from, () => _StopNode(id: from, actualBusId: null));
			stopNodes.putIfAbsent(to, () => _StopNode(id: to, actualBusId: null));
			undirected.putIfAbsent(from, () => <int>{}).add(to);
			undirected.putIfAbsent(to, () => <int>{}).add(from);
		}

		undirected.putIfAbsent(rootStopId, () => <int>{});

		final dist = <int, int>{};
		final bfs = Queue<int>()..add(rootStopId);
		dist[rootStopId] = 0;
		while (bfs.isNotEmpty) {
			final node = bfs.removeFirst();
			final d = dist[node]!;
			for (final nxt in undirected[node] ?? const <int>{}) {
				if (dist.containsKey(nxt)) continue;
				dist[nxt] = d + 1;
				bfs.add(nxt);
			}
		}

		final parentOf = <int, int?>{};
		final childrenByParent = <int, List<int>>{};
		const unreachable = 1 << 30;

		for (final node in stopNodes.keys) {
			if (node == rootStopId) {
				parentOf[node] = null;
				continue;
			}

			final nodeDist = dist[node] ?? unreachable;
			int? chosenParent;
			var bestParentDist = unreachable;

			for (final n in undirected[node] ?? const <int>{}) {
				final nDist = dist[n] ?? unreachable;
				final isBetter =
						nDist < bestParentDist ||
						(nDist == bestParentDist && chosenParent != null && n < chosenParent);
				if (isBetter) {
					bestParentDist = nDist;
					chosenParent = n;
				}
			}

			if (chosenParent != null && bestParentDist < nodeDist) {
				parentOf[node] = chosenParent;
				childrenByParent.putIfAbsent(chosenParent, () => <int>[]).add(node);
			} else {
				parentOf[node] = null;
			}
		}

		final topo = stopNodes.keys.toList()
			..sort((a, b) {
				final da = dist[a] ?? unreachable;
				final db = dist[b] ?? unreachable;
				if (da != db) {
					return db.compareTo(da); // bottom-up
				}
				return a.compareTo(b);
			});

		final connectedStops = dist.keys.toSet();
		final leafStopIds = stopNodes.keys
				.where((id) {
					if (id == rootStopId || !connectedStops.contains(id)) return false;
					final degreeInRootComponent = (undirected[id] ?? const <int>{})
							.where(connectedStops.contains)
							.length;
					return degreeInRootComponent <= 1;
				})
				.toSet();

		final busById = {for (final b in buses) b.id: b};
		final totalFleetCapacity = buses.fold<int>(
			0,
			(sum, b) => sum + b.totalCapacity,
		);
		if (eligibleStudents.length > totalFleetCapacity) {
			throw Exception(
				'Insufficient total fleet capacity. '
				'Eligible=${eligibleStudents.length}, capacity=$totalFleetCapacity',
			);
		}

		final arrivingBusesAtStop = <int, Set<int>>{};
		final usedBusIds = <int>{};
		final unusedBusIds = buses.map((b) => b.id).toSet();
		final allocations = <_Allocation>[];

		for (final stopId in topo) {
			final waiting = Queue<_StudentNode>()
				..addAll(studentsByStop[stopId] ?? Queue<_StudentNode>());

			final candidateBusIds = <int>{
				...?arrivingBusesAtStop[stopId],
			};
			final actualBus = stopNodes[stopId]?.actualBusId;
			if (actualBus != null && busById.containsKey(actualBus)) {
				candidateBusIds.add(actualBus);
			}

			// Also consider actual buses of neighboring stops (junction support).
			for (final n in undirected[stopId] ?? const <int>{}) {
				final nActualBus = stopNodes[n]?.actualBusId;
				if (nActualBus != null && busById.containsKey(nActualBus)) {
					candidateBusIds.add(nActualBus);
				}
			}

			while (waiting.isNotEmpty) {
				final nextBus = _pickNextBus(
					candidateBusIds: candidateBusIds,
					preferredBusId: actualBus,
					usedBusIds: usedBusIds,
					busById: busById,
				);

				int? chosenBusId = nextBus;

				if (chosenBusId == null) {
					// Min-bus strategy: try already-used buses first.
					final usedFallback = _pickAnyUsedBusWithRemaining(
						usedBusIds: usedBusIds,
						busById: busById,
					);
					if (usedFallback != null) {
						chosenBusId = usedFallback;
						candidateBusIds.add(chosenBusId);
					} else {
						final activated = _activateUnusedBus(unusedBusIds, busById);
						if (activated != null) {
							chosenBusId = activated;
							candidateBusIds.add(chosenBusId);
						} else {
							// Last-resort: any bus in fleet with remaining capacity.
							final fallback = _pickAnyBusWithRemaining(busById);
							if (fallback == null) {
								throw Exception(
									'Allocation failed at stop $stopId: no bus with remaining capacity.',
								);
							}
							chosenBusId = fallback;
							candidateBusIds.add(chosenBusId);
						}
					}
				}

				final bus = busById[chosenBusId]!;
				usedBusIds.add(chosenBusId);
				unusedBusIds.remove(chosenBusId);

				if (bus.remainingCapacity <= 0) {
					candidateBusIds.remove(chosenBusId);
					continue;
				}

				final canTake = bus.remainingCapacity < waiting.length
						? bus.remainingCapacity
						: waiting.length;

				for (var i = 0; i < canTake; i++) {
					final student = waiting.removeFirst();
					bus.remainingCapacity -= 1;
					bus.allocatedCount += 1;
					allocations.add(
						_Allocation(
							studentId: student.id,
							stopId: stopId,
							allocatedBusId: bus.id,
						),
					);
				}
			}

			final nextStop = parentOf[stopId];
			if (nextStop != null) {
				final propagateBuses = arrivingBusesAtStop.putIfAbsent(
					nextStop,
					() => <int>{},
				);
				for (final busId in candidateBusIds) {
					final b = busById[busId];
					if (b != null && b.remainingCapacity > 0) {
						propagateBuses.add(busId);
					}
				}
			}
		}

		if (allocations.length != eligibleStudents.length) {
			throw Exception(
				'Coverage check failed. Assigned ${allocations.length} / '
				'${eligibleStudents.length} eligible students.',
			);
		}

		final insertStatements = allocations
				.map(
					(a) => "INSERT INTO public.daily_manifests "
							'(manifest_date, student_id, allocated_bus_id) '
							"VALUES ('$dateIso', '${a.studentId}', ${a.allocatedBusId});",
				)
				.toList();

		if (persistToDatabase && allocations.isNotEmpty) {
			if (clearAllExistingManifests) {
				await _client
						.from('daily_manifests')
						.delete()
						.not('id', 'is', null);
			} else {
				final studentIds = allocations.map((e) => e.studentId).toSet().toList();
				await _client
						.from('daily_manifests')
						.delete()
						.eq('manifest_date', dateIso)
						.inFilter('student_id', studentIds);
			}

			const chunkSize = 400;
			for (var i = 0; i < allocations.length; i += chunkSize) {
				final end = (i + chunkSize < allocations.length)
						? i + chunkSize
						: allocations.length;
				final chunk = allocations.sublist(i, end);
				final payload = chunk
						.map(
							(a) => {
								'manifest_date': dateIso,
								'student_id': a.studentId,
								'allocated_bus_id': a.allocatedBusId,
							},
						)
						.toList();
				await _client.from('daily_manifests').insert(payload);
			}
		}

		final overNinety = buses
				.where((b) => b.totalCapacity > 0 && (b.allocatedCount / b.totalCapacity) >= 0.9)
				.toList()
			..sort((a, b) => b.allocatedCount.compareTo(a.allocatedCount));

		final summary = AllocationSummary(
			targetDate: dateIso,
			rootStopId: rootStopId,
			totalStudents: eligibleStudents.length,
			staffAllocatedCount: staffAllocatedCount,
			totalBusesUsed: usedBusIds.length,
			totalLeafStops: leafStopIds.length,
			overNinetyPercentBuses: overNinety
					.map(
						(b) => BusUtilization(
							busId: b.id,
							busNumber: b.busNumber,
							allocated: b.allocatedCount,
							capacity: b.totalCapacity,
						),
					)
					.toList(),
		);

		return AllocationRunResult(
			insertStatements: insertStatements,
			allocations: allocations
					.map(
						(a) => AllocationRow(
							studentId: a.studentId,
							boardingStopId: a.stopId,
							allocatedBusId: a.allocatedBusId,
						),
					)
					.toList(),
			summary: summary,
		);
	}

	static String _toDateOnly(DateTime dt) {
		final y = dt.year.toString().padLeft(4, '0');
		final m = dt.month.toString().padLeft(2, '0');
		final d = dt.day.toString().padLeft(2, '0');
		return '$y-$m-$d';
	}

	static int? _toInt(dynamic value) {
		if (value is int) return value;
		if (value is num) return value.toInt();
		if (value == null) return null;
		return int.tryParse(value.toString());
	}

	static int? _pickNextBus({
		required Set<int> candidateBusIds,
		required int? preferredBusId,
		required Set<int> usedBusIds,
		required Map<int, _BusState> busById,
	}) {
		final viable = <int>[];
		for (final id in candidateBusIds) {
			final bus = busById[id];
			if (bus == null || bus.remainingCapacity <= 0) continue;
			viable.add(id);
		}

		if (viable.isEmpty) return null;

		// Min-bus strategy: prioritize already-used buses.
		int? bestUsed;
		var bestUsedRemaining = -1;
		for (final id in viable) {
			if (!usedBusIds.contains(id)) continue;
			final remaining = busById[id]!.remainingCapacity;
			if (remaining > bestUsedRemaining) {
				bestUsedRemaining = remaining;
				bestUsed = id;
			}
		}
		if (bestUsed != null) return bestUsed;

		// If no used bus exists in candidates, prefer actual bus if available.
		if (preferredBusId != null && viable.contains(preferredBusId)) {
			return preferredBusId;
		}

		int? best;
		var bestRemaining = -1;
		for (final id in viable) {
			final remaining = busById[id]!.remainingCapacity;
			if (remaining > bestRemaining) {
				bestRemaining = remaining;
				best = id;
			}
		}
		return best;
	}

	static int? _activateUnusedBus(
		Set<int> unusedBusIds,
		Map<int, _BusState> busById,
	) {
		int? best;
		var bestRemaining = -1;
		for (final id in unusedBusIds) {
			final bus = busById[id];
			if (bus == null || bus.remainingCapacity <= 0) continue;
			if (bus.remainingCapacity > bestRemaining) {
				bestRemaining = bus.remainingCapacity;
				best = id;
			}
		}
		return best;
	}

	static int? _pickAnyBusWithRemaining(Map<int, _BusState> busById) {
		int? best;
		var bestRemaining = -1;
		for (final bus in busById.values) {
			if (bus.remainingCapacity <= 0) continue;
			if (bus.remainingCapacity > bestRemaining) {
				bestRemaining = bus.remainingCapacity;
				best = bus.id;
			}
		}
		return best;
	}

	static int? _pickAnyUsedBusWithRemaining({
		required Set<int> usedBusIds,
		required Map<int, _BusState> busById,
	}) {
		int? best;
		var bestRemaining = -1;
		for (final id in usedBusIds) {
			final bus = busById[id];
			if (bus == null || bus.remainingCapacity <= 0) continue;
			if (bus.remainingCapacity > bestRemaining) {
				bestRemaining = bus.remainingCapacity;
				best = id;
			}
		}
		return best;
	}
}

class AllocationRunResult {
	AllocationRunResult({
		required this.insertStatements,
		required this.allocations,
		required this.summary,
	});

	final List<String> insertStatements;
	final List<AllocationRow> allocations;
	final AllocationSummary summary;

	String get summaryReport {
		final buffer = StringBuffer()
			..writeln('Date: ${summary.targetDate}')
			..writeln('Total Students: ${summary.totalStudents}')
			..writeln('Staff Allocated: ${summary.staffAllocatedCount}')
			..writeln('Total Buses Used: ${summary.totalBusesUsed}')
			..writeln('Buses > 90% Capacity:');

		if (summary.overNinetyPercentBuses.isEmpty) {
			buffer.writeln('- None');
		} else {
			for (final bus in summary.overNinetyPercentBuses) {
				final utilization = (bus.allocated / bus.capacity) * 100;
				buffer.writeln(
					'- Bus ID ${bus.busId} (No ${bus.busNumber}): '
					'${bus.allocated}/${bus.capacity} (${utilization.toStringAsFixed(1)}%)',
				);
			}
		}
		return buffer.toString();
	}
}

class AllocationRow {
	AllocationRow({
		required this.studentId,
		required this.boardingStopId,
		required this.allocatedBusId,
	});

	final String studentId;
	final int boardingStopId;
	final int allocatedBusId;
}

class AllocationSummary {
	AllocationSummary({
		required this.targetDate,
		required this.rootStopId,
		required this.totalStudents,
		required this.staffAllocatedCount,
		required this.totalBusesUsed,
		required this.totalLeafStops,
		required this.overNinetyPercentBuses,
	});

	final String targetDate;
	final int rootStopId;
	final int totalStudents;
	final int staffAllocatedCount;
	final int totalBusesUsed;
	final int totalLeafStops;
	final List<BusUtilization> overNinetyPercentBuses;
}

class BusUtilization {
	BusUtilization({
		required this.busId,
		required this.busNumber,
		required this.allocated,
		required this.capacity,
	});

	final int busId;
	final int busNumber;
	final int allocated;
	final int capacity;
}

class _Allocation {
	_Allocation({
		required this.studentId,
		required this.stopId,
		required this.allocatedBusId,
	});

	final String studentId;
	final int stopId;
	final int allocatedBusId;
}

class _StudentNode {
	_StudentNode({
		required this.id,
		required this.fullName,
		required this.course,
		required this.semester,
		required this.boardingStopId,
	});

	final String id;
	final String fullName;
	final String? course;
	final int? semester;
	final int? boardingStopId;

	factory _StudentNode.fromMap(Map<String, dynamic> map) {
		return _StudentNode(
			id: map['id'].toString(),
			fullName: (map['full_name'] ?? '').toString(),
			course: map['course']?.toString(),
			semester: BottomUpGreedyFlowAllocator._toInt(map['semester']),
			boardingStopId: BottomUpGreedyFlowAllocator._toInt(map['boarding_stop_id']),
		);
	}
}

class _StopNode {
	_StopNode({required this.id, required this.actualBusId});

	final int id;
	final int? actualBusId;

	factory _StopNode.fromMap(Map<String, dynamic> map) {
		return _StopNode(
			id: BottomUpGreedyFlowAllocator._toInt(map['id'])!,
			actualBusId: BottomUpGreedyFlowAllocator._toInt(map['actual_bus']),
		);
	}
}

class _BusState {
	_BusState({
		required this.id,
		required this.busNumber,
		required this.totalCapacity,
		required this.remainingCapacity,
		required this.allocatedCount,
	});

	final int id;
	final int busNumber;
	final int totalCapacity;
	int remainingCapacity;
	int allocatedCount;

	factory _BusState.fromMap(Map<String, dynamic> map) {
		final id = BottomUpGreedyFlowAllocator._toInt(map['id'])!;
		final busNumber = BottomUpGreedyFlowAllocator._toInt(map['bus_number'])!;
		final capacity = BottomUpGreedyFlowAllocator._toInt(map['total_capacity'])!;
		return _BusState(
			id: id,
			busNumber: busNumber,
			totalCapacity: capacity,
			remainingCapacity: capacity,
			allocatedCount: 0,
		);
	}
}
