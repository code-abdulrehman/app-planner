import Sortable from "sortablejs";

const SortableHook = {
    mounted() {
        this.initSortable();
    },
    updated() {
        this.initSortable();
    },
    initSortable() {
        const group = this.el.dataset.group;
        const status = this.el.dataset.status;

        this.sortable = new Sortable(this.el, {
            group: group,
            animation: 150,
            ghostClass: "bg-primary/10",
            dragClass: "shadow-2xl",
            onEnd: (evt) => {
                const id = evt.item.dataset.id;
                const toStatus = evt.to.dataset.status;
                const newIndex = evt.newIndex;

                this.pushEvent("reorder", {
                    id: id,
                    to_status: toStatus,
                    new_index: newIndex
                });
            }
        });
    }
};

export default SortableHook;
