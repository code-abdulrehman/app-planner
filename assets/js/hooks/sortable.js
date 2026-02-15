import Sortable from "sortablejs";

const SortableHook = {
    mounted() {
        this.initSortable();
    },
    updated() {
        this.initSortable();
    },
    initSortable() {
        if (this.sortable) this.sortable.destroy();
        const group = this.el.dataset.group;

        this.sortable = new Sortable(this.el, {
            group: group,
            animation: 150,
            ghostClass: "bg-primary/10",
            dragClass: "shadow-2xl",
            filter: ".js-no-drag", // Elements with this class will not be draggable
            onEnd: (evt) => {
                const id = evt.item.dataset.id;
                const toStatus = evt.to.dataset.status;
                const newIndex = evt.newIndex;

                if (id && toStatus) {
                    this.pushEvent("reorder", {
                        id: id,
                        to_status: toStatus,
                        new_index: newIndex
                    });
                }
            }
        });
    }
};

export default SortableHook;
