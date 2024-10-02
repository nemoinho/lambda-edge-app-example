<script setup lang="ts">
    const newName = defineModel('')
    const route = useRoute()
    const name = computed(() => route.query.name);
    newName.value = name.value
    const { data } = await useFetch('/api/greet', {query: { name }})
    const changeNameWithoutReload = () => navigateTo('/?' + new URLSearchParams([["name", newName.value]]))
    const changeNameWithHardReload = () => location.href = '/?' + new URLSearchParams([["name", newName.value]])
</script>

<template>
    <h1>{{ data.greet }}</h1>
    <p>Lorem</p>
    <input v-model="newName"/>
    <button style="margin-left: 1em" @click="changeNameWithoutReload">Change name without reload</button>
    <button style="margin-left: 1em" @click="changeNameWithHardReload">Change name with hard reload</button>
</template>
