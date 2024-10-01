export default defineEventHandler((event) => ({
    greet: `Hello ${getQuery(event).name || "World"} from server`
}))
