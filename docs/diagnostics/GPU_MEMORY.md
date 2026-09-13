# Process GPU memory and activity APIs

Investigated September 13, 2026 on macOS 26.6, Apple M3 Pro, without root privileges or
changes to task access. The earlier statement that no per-process graphics memory
accounting was available was too broad. Complete Metal allocation inventories for
arbitrary PIDs remain unavailable through the APIs investigated, but kernel graphics
ledgers provide useful process-specific accounting.

## APIs investigated

| Interface | Scope and outcome |
| --- | --- |
| `task_name_for_pid` + `task_info(TASK_VM_INFO)` | Implemented. Public SDK revision 3 contains four signed graphics-ledger balances. Task access can be denied; returned count is checked before using the fields. Negative balances are unavailable, and measured zero is preserved. |
| `MTLDevice.currentAllocatedSize` | Resources owned by the device object in the caller. Useful for instrumenting an application's own Metal allocations; it has no PID argument to inspect another application's device objects. Used as an independent counter in the reproducible workload below. |
| Metal counter sample buffers and command-buffer timestamps | Require instrumentation of submitted Metal work. They cannot inspect arbitrary other-process workloads from this monitor. |
| `TASK_POWER_INFO_V2.gpu_energy.task_gpu_utilisation` | XNU fills this from `task_gpu_ns`, but live reads here returned zero for processes with independently observed GPU activity. Not used as a fallback: successful retrieval is not proof of working GPU instrumentation. |
| Public IOKit registry reads | Existing driver execution counters now produce per-device process rates, observed times, and sampled-client coverage. Registry properties are driver-defined, not a cross-vendor contract. No speculative memory property names are parsed. |
| IOReport / private graphics frameworks | Not integrated. They do not provide a documented, supported arbitrary-process allocation inventory; adding private dependencies would not establish correct memory attribution. |

Sources: Apple's [task-info structure](https://github.com/apple-oss-distributions/xnu/blob/main/osfmk/mach/task_info.h), [task-info implementation](https://github.com/apple-oss-distributions/xnu/blob/main/osfmk/kern/task.c), [graphics ledger accounting](https://github.com/apple-oss-distributions/xnu/blob/main/osfmk/vm/vm_object.c), [Metal allocated-size API](https://developer.apple.com/documentation/metal/mtldevice/currentallocatedsize), and [Metal counter sampling](https://developer.apple.com/documentation/metal/sampling-gpu-data-into-counter-sample-buffers).

## Accounting definitions

- **Charged**: uncompressed graphics-tagged balance charged to the process footprint
  (`ledger_tag_graphics_footprint`). The table's **Graphics charged** column uses this field.
- **Charged compressed**: logical compressed bytes in that charged category
  (`ledger_tag_graphics_footprint_compressed`).
- **Excluded** and **Excluded compressed**: corresponding balances excluded from footprint
  (`ledger_tag_graphics_nofootprint` and its compressed counterpart). Volatile or explicitly
  excluded graphics allocations can be accounted here.

These are process ledgers across GPUs, not per-device allocations. They may include
shared surfaces or driver-managed graphics objects and do not enumerate every Metal
buffer/texture. The compressed balances are logical sizes, not physical compressor
storage. The UI intentionally does not sum these into a purported GPU-memory total or
subtract them from a device allocation counter. Tree subtotals carry the shared-memory
and partial-coverage caveats used by other memory columns.

## Live observations and reproducible workload

A direct unprivileged task-info probe returned count 93 and succeeded for the installed
Activity Monitor: charged 104,726,528 bytes, charged compressed 999,424 bytes, excluded
7,028,736 bytes, excluded compressed zero. A Chrome GPU helper returned nonzero charged
and compressed balances. PID 1 denied task-name access with Mach status 5; that is
unavailable data, not zero memory. The native GPU power counter returned zero for both
of those active GPU processes and therefore was not adopted.

Run `swift scripts/gpu-memory-workload.swift` (optional `--hold` retains allocations for
30 seconds for external process inspection). The workload creates four private 16 MiB
buffers and fills them with Metal blit commands, checking completion before sampling.

| Phase | Metal currentAllocatedSize | Graphics charged |
| --- | ---: | ---: |
| Before buffers | 475,136 | 81,920 |
| 64 MiB private buffers filled | 67,584,000 | 130,498,560 |
| Buffers released, immediate sample | 475,136 | 130,498,560 |

These observed counters deliberately differ. Metal resources returned to baseline while
the kernel balance remained elevated in the immediate sample; this may reflect driver retention or delayed accounting.
The observation does not establish a leak or a one-to-one mapping between these APIs.
No equality assertion between the counters is appropriate. Intel graphics-ledger and
physical multi-GPU memory behavior have not been validated on this machine.

## Collection and coverage

Graphics balances reuse the existing background task-memory query (about every five
seconds). Process start identity is checked before publishing cached details. A selected
GPU diagnostic page can also read a timestamped snapshot and rechecks identity afterward.
History deduplicates cached samples, sorts delayed results, preserves unavailable samples,
and retains at most 901 readings / fifteen minutes. JSON exports include the four optional
balances, capture times, availability text and per-device process activity.

Device rates share the existing monotonic counter tracker. Duplicate clients are ignored;
PID reuse, counter rollback, changed queue counters and long gaps rebaseline. A device's
observed time survives vanished clients until the process exits; current rate and client
coverage reflect only this sample. Rates include only valid consecutive client pairs,
so partial coverage is shown as measured/current clients rather than silently claiming
full process coverage. The aggregate remains the sum of valid reporting-device rates.
