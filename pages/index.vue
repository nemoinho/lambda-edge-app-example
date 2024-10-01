<script setup lang="ts">
    const { data } = useFetch('/api/greet?name')
</script>

<template>
    <h1>{{ data.greet }}</h1>
    <p>Lorem</p>
</template>
