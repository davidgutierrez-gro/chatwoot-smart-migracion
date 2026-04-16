<script setup>
import KanbanCard from './KanbanCard.vue';

const props = defineProps({
  label: {
    type: Object,
    required: true,
  },
  conversations: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['cardClick']);

const handleCardClick = conversation => {
  emit('cardClick', conversation);
};
</script>

<template>
  <div
    class="flex flex-col min-w-[16rem] w-64 bg-slate-50 dark:bg-slate-800 rounded-lg overflow-hidden flex-shrink-0 max-h-full"
  >
    <div
      class="flex items-center justify-between px-3 py-2 border-b border-slate-200 dark:border-slate-700"
      :style="{ borderTop: `3px solid ${label.color || '#94a3b8'}` }"
    >
      <span
        class="text-sm font-semibold text-slate-700 dark:text-slate-200 truncate"
        :title="label.title"
      >
        {{ label.title }}
      </span>
      <span
        class="text-xs text-slate-500 dark:text-slate-400 bg-slate-200 dark:bg-slate-700 rounded-full px-2 py-0.5 ml-2 flex-shrink-0"
      >
        {{ conversations.length }}
      </span>
    </div>
    <div class="flex flex-col gap-2 p-2 overflow-y-auto flex-1">
      <KanbanCard
        v-for="conv in conversations"
        :key="conv.id"
        :conversation="conv"
        @click="handleCardClick(conv)"
      />
      <p
        v-if="conversations.length === 0"
        class="text-xs text-slate-400 dark:text-slate-500 text-center py-4"
      >
        Sin conversaciones
      </p>
    </div>
  </div>
</template>
