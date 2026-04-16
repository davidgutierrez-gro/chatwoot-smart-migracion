<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import KanbanColumn from './KanbanColumn.vue';

const props = defineProps({
  conversations: {
    type: Array,
    default: () => [],
  },
});

const store = useStore();
const router = useRouter();

const kanbanLabels = computed(
  () => store.getters['labels/getKanbanLabels'] || []
);

const columns = computed(() => {
  const labelTitles = kanbanLabels.value.map(l => l.title);
  const map = {};
  labelTitles.forEach(title => {
    map[title] = [];
  });
  const uncategorized = [];

  props.conversations.forEach(conv => {
    const convLabels = conv.labels || [];
    const match = convLabels.find(l => labelTitles.includes(l));
    if (match) {
      map[match].push(conv);
    } else {
      uncategorized.push(conv);
    }
  });

  const cols = kanbanLabels.value.map(label => ({
    label,
    conversations: map[label.title] || [],
  }));

  if (uncategorized.length > 0) {
    cols.push({
      label: { id: null, title: 'Sin etiqueta', color: '#94a3b8' },
      conversations: uncategorized,
    });
  }

  return cols;
});

const handleCardClick = conversation => {
  router.push({
    name: 'conversation',
    params: { conversation_id: conversation.id },
  });
};
</script>

<template>
  <div class="flex flex-row gap-4 overflow-x-auto h-full p-4 items-start">
    <KanbanColumn
      v-for="col in columns"
      :key="col.label.title"
      :label="col.label"
      :conversations="col.conversations"
      @card-click="handleCardClick"
    />
    <p
      v-if="columns.length === 0"
      class="text-sm text-slate-500 dark:text-slate-400 w-full text-center py-8"
    >
      No hay etiquetas configuradas. Ve a Configuración → Etiquetas para crearlas.
    </p>
  </div>
</template>
