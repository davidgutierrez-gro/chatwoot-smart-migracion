<script setup>
import { computed } from 'vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['click']);

const contactName = computed(
  () => props.conversation.meta?.sender?.name || 'Sin nombre'
);
const phoneNumber = computed(
  () => props.conversation.meta?.sender?.phone_number || ''
);
const assigneeName = computed(
  () => props.conversation.meta?.assignee?.name || null
);
const isUnattended = computed(() => !!props.conversation.waiting_since);

const waitingTime = computed(() => {
  if (!props.conversation.waiting_since) return null;
  const waitingSince = props.conversation.waiting_since;
  const date =
    typeof waitingSince === 'number'
      ? new Date(waitingSince * 1000)
      : new Date(waitingSince);
  const diffMs = Date.now() - date.getTime();
  const diffMin = Math.floor(diffMs / 60000);
  if (diffMin < 60) return `${diffMin}m`;
  const diffH = Math.floor(diffMin / 60);
  if (diffH < 24) return `${diffH}h`;
  return `${Math.floor(diffH / 24)}d`;
});
</script>

<template>
  <div
    class="bg-white dark:bg-slate-700 rounded-md shadow-sm border border-slate-200 dark:border-slate-600 p-3 cursor-pointer hover:shadow-md transition-shadow select-none"
    :class="{ 'border-l-4 border-l-amber-500': isUnattended }"
    @click="emit('click', conversation)"
  >
    <div
      v-if="isUnattended"
      class="flex items-center gap-1 text-amber-600 dark:text-amber-400 text-xs mb-2 font-medium"
    >
      <span class="w-2 h-2 rounded-full bg-amber-500 flex-shrink-0" />
      Desatendido{{ waitingTime ? ` · ${waitingTime}` : '' }}
    </div>
    <p class="text-sm font-semibold text-slate-800 dark:text-slate-100 truncate">
      {{ contactName }}
    </p>
    <p
      v-if="phoneNumber"
      class="text-xs text-slate-500 dark:text-slate-400 mt-0.5 truncate"
    >
      {{ phoneNumber }}
    </p>
    <div v-if="assigneeName" class="mt-2 flex items-center gap-1">
      <span class="text-xs text-slate-500 dark:text-slate-400 truncate">
        → {{ assigneeName }}
      </span>
    </div>
  </div>
</template>
