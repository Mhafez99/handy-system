"use client";

import { useEffect, useMemo, useState } from "react";
import {
  createArea,
  loadAreas,
  type AdminArea,
  updateArea,
} from "@/lib/admin";

type AreasPanelProps = {
  onMessage: (message: string) => void;
  onError: (error: string) => void;
};

type AreaActionState = {
  areaId: number;
  type: "toggle" | "save";
} | null;

const emptyForm = {
  governorate: "",
  name: "",
  sortOrder: "0",
};

export function AreasPanel({
  onMessage,
  onError,
}: AreasPanelProps) {
  const [areas, setAreas] = useState<AdminArea[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isCreating, setIsCreating] = useState(false);
  const [actionState, setActionState] = useState<AreaActionState>(null);
  const [createForm, setCreateForm] = useState(emptyForm);
  const [editingAreaId, setEditingAreaId] = useState<number | null>(null);
  const [editForm, setEditForm] = useState(emptyForm);
  const [editIsActive, setEditIsActive] = useState(true);

  const activeCount = useMemo(
    () => areas.filter((area) => area.is_active).length,
    [areas],
  );

  async function reloadAreas() {
    onError("");
    setIsLoading(true);

    try {
      const nextAreas = await loadAreas();
      setAreas(nextAreas);
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    let cancelled = false;

    loadAreas()
      .then((nextAreas) => {
        if (!cancelled) {
          setAreas(nextAreas);
        }
      })
      .catch((caughtError) => {
        if (!cancelled) {
          onError(getErrorMessage(caughtError));
        }
      })
      .finally(() => {
        if (!cancelled) {
          setIsLoading(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [onError]);

  async function handleCreate(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    onError("");
    onMessage("");
    setIsCreating(true);

    try {
      await createArea({
        governorate: createForm.governorate,
        name: createForm.name,
        sortOrder: Number.parseInt(createForm.sortOrder, 10) || 0,
      });
      setCreateForm(emptyForm);
      onMessage("تمت إضافة المنطقة بنجاح.");
      await reloadAreas();
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setIsCreating(false);
    }
  }

  function startEditing(area: AdminArea) {
    setEditingAreaId(area.id);
    setEditForm({
      governorate: area.governorate,
      name: area.name,
      sortOrder: String(area.sort_order),
    });
    setEditIsActive(area.is_active);
  }

  function cancelEditing() {
    setEditingAreaId(null);
  }

  async function handleSaveEdit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (editingAreaId == null) {
      return;
    }

    onError("");
    onMessage("");
    setActionState({ areaId: editingAreaId, type: "save" });

    try {
      await updateArea({
        areaId: editingAreaId,
        governorate: editForm.governorate,
        name: editForm.name,
        sortOrder: Number.parseInt(editForm.sortOrder, 10) || 0,
        isActive: editIsActive,
      });
      setEditingAreaId(null);
      onMessage("تم تحديث المنطقة.");
      await reloadAreas();
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setActionState(null);
    }
  }

  async function handleToggleActive(area: AdminArea) {
    onError("");
    onMessage("");
    setActionState({ areaId: area.id, type: "toggle" });

    try {
      await updateArea({
        areaId: area.id,
        governorate: area.governorate,
        name: area.name,
        sortOrder: area.sort_order,
        isActive: !area.is_active,
      });
      onMessage(area.is_active ? "تم إخفاء المنطقة." : "تم تفعيل المنطقة.");
      await reloadAreas();
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setActionState(null);
    }
  }

  return (
    <>
      <section className="stats-grid">
        <article className="stat-card">
          <span>إجمالي المناطق</span>
          <strong>{areas.length}</strong>
        </article>
        <article className="stat-card">
          <span>المناطق النشطة</span>
          <strong>{isLoading ? "..." : activeCount}</strong>
        </article>
      </section>

      <section className="panel">
        <h2>إضافة منطقة جديدة</h2>
        <p className="muted">
          المناطق النشطة فقط تظهر في تطبيق الهاتف عند التسجيل وإنشاء الطلبات.
        </p>

        <form className="form area-form" onSubmit={handleCreate}>
          <label>
            المحافظة
            <input
              value={createForm.governorate}
              onChange={(event) =>
                setCreateForm((current) => ({
                  ...current,
                  governorate: event.target.value,
                }))
              }
              placeholder="مثل: القاهرة"
              required
            />
          </label>
          <label>
            المنطقة
            <input
              value={createForm.name}
              onChange={(event) =>
                setCreateForm((current) => ({
                  ...current,
                  name: event.target.value,
                }))
              }
              placeholder="مثل: مدينة نصر"
              required
            />
          </label>
          <label>
            ترتيب العرض
            <input
              dir="ltr"
              type="number"
              min="0"
              value={createForm.sortOrder}
              onChange={(event) =>
                setCreateForm((current) => ({
                  ...current,
                  sortOrder: event.target.value,
                }))
              }
            />
          </label>
          <button className="primary-button" disabled={isCreating}>
            {isCreating ? "جاري الإضافة..." : "إضافة المنطقة"}
          </button>
        </form>
      </section>

      <section className="areas-list">
        {isLoading ? (
          <div className="panel">
            <p className="muted">جاري تحميل المناطق...</p>
          </div>
        ) : areas.length === 0 ? (
          <div className="panel empty">
            <h2>لا توجد مناطق بعد</h2>
            <p className="muted">أضف أول منطقة من النموذج أعلاه.</p>
          </div>
        ) : (
          areas.map((area) => (
            <AreaCard
              key={area.id}
              area={area}
              isEditing={editingAreaId === area.id}
              editForm={editForm}
              editIsActive={editIsActive}
              actionState={actionState}
              onStartEditing={() => startEditing(area)}
              onCancelEditing={cancelEditing}
              onEditFormChange={setEditForm}
              onEditIsActiveChange={setEditIsActive}
              onSaveEdit={handleSaveEdit}
              onToggleActive={() => handleToggleActive(area)}
            />
          ))
        )}
      </section>
    </>
  );
}

function AreaCard({
  area,
  isEditing,
  editForm,
  editIsActive,
  actionState,
  onStartEditing,
  onCancelEditing,
  onEditFormChange,
  onEditIsActiveChange,
  onSaveEdit,
  onToggleActive,
}: {
  area: AdminArea;
  isEditing: boolean;
  editForm: typeof emptyForm;
  editIsActive: boolean;
  actionState: AreaActionState;
  onStartEditing: () => void;
  onCancelEditing: () => void;
  onEditFormChange: (form: typeof emptyForm) => void;
  onEditIsActiveChange: (isActive: boolean) => void;
  onSaveEdit: (event: React.FormEvent<HTMLFormElement>) => void;
  onToggleActive: () => void;
}) {
  const isSaving =
    actionState?.areaId === area.id && actionState.type === "save";
  const isToggling =
    actionState?.areaId === area.id && actionState.type === "toggle";
  const isBusy = Boolean(actionState);

  if (isEditing) {
    return (
      <article className="worker-card area-card">
        <h2>تعديل المنطقة</h2>
        <form className="form area-form" onSubmit={onSaveEdit}>
          <label>
            المحافظة
            <input
              value={editForm.governorate}
              onChange={(event) =>
                onEditFormChange({
                  ...editForm,
                  governorate: event.target.value,
                })
              }
              required
            />
          </label>
          <label>
            المنطقة
            <input
              value={editForm.name}
              onChange={(event) =>
                onEditFormChange({ ...editForm, name: event.target.value })
              }
              required
            />
          </label>
          <label>
            ترتيب العرض
            <input
              dir="ltr"
              type="number"
              min="0"
              value={editForm.sortOrder}
              onChange={(event) =>
                onEditFormChange({
                  ...editForm,
                  sortOrder: event.target.value,
                })
              }
            />
          </label>
          <label className="checkbox-field">
            <input
              type="checkbox"
              checked={editIsActive}
              onChange={(event) => onEditIsActiveChange(event.target.checked)}
            />
            <span>المنطقة نشطة في التطبيق</span>
          </label>
          <div className="card-actions">
            <button className="primary-button" disabled={isSaving}>
              {isSaving ? "جاري الحفظ..." : "حفظ التعديل"}
            </button>
            <button
              type="button"
              className="ghost-button"
              disabled={isBusy}
              onClick={onCancelEditing}
            >
              إلغاء
            </button>
          </div>
        </form>
      </article>
    );
  }

  return (
    <article className="worker-card area-card">
      <div className="worker-header">
        <div>
          <h2>{area.name}</h2>
          <p className="muted">{area.governorate}</p>
        </div>
        <span className={`badge ${area.is_active ? "" : "badge-muted"}`}>
          {area.is_active ? "نشطة" : "مخفية"}
        </span>
      </div>

      <div className="worker-details">
        <p>
          <strong>الترتيب:</strong> {area.sort_order}
        </p>
        <p>
          <strong>تاريخ الإضافة:</strong>{" "}
          {new Date(area.created_at).toLocaleDateString("ar-EG")}
        </p>
      </div>

      <div className="card-actions">
        <button
          className="secondary-button"
          disabled={isBusy}
          onClick={onStartEditing}
        >
          تعديل
        </button>
        <button
          className={area.is_active ? "danger-button" : "primary-button"}
          disabled={isBusy}
          onClick={onToggleActive}
        >
          {isToggling
            ? "جاري التحديث..."
            : area.is_active
              ? "إخفاء"
              : "تفعيل"}
        </button>
      </div>
    </article>
  );
}

function getErrorMessage(error: unknown) {
  if (error instanceof Error) {
    if (error.message.includes("duplicate key")) {
      return "هذه المنطقة موجودة بالفعل في نفس المحافظة.";
    }

    if (error.message === "Admin access required") {
      return "ليس لديك صلاحية إدارية.";
    }

    return error.message;
  }

  return "حدث خطأ غير متوقع.";
}
