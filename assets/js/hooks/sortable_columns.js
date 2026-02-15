import Sortable from "sortablejs";

const SortableColumnsHook = {
    mounted() {
        this.initSortable();
    },
    updated() {
        this.initSortable();
    },
    initSortable() {
        if (this.sortable) this.sortable.destroy();
        this.sortable = new Sortable(this.el, {
            animation: 150,
            ghostClass: "bg-primary/5",
            dragClass: "shadow-2xl",
            handle: ".column-handle",
            onEnd: (evt) => {
                const status = evt.item.dataset.status;
                const newIndex = evt.newIndex;

                if (status) {
                    this.pushEvent("reorder_columns", {
                        status: status,
                        new_index: newIndex
                    });
                }
            }
        });
    }
};

export default SortableColumnsHook;
