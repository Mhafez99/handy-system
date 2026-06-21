"use client";

import { useEffect, useMemo, useState } from "react";
import {
  createCategory,
  createService,
  loadCategories,
  loadServices,
  updateCategory,
  updateService,
  type AdminCategory,
  type AdminService,
} from "@/lib/admin";

type ServicesPanelProps = {
  refreshToken: number;
  onMessage: (message: string) => void;
  onError: (error: string) => void;
};

type CategoryActionState = {
  categoryId: number;
  type: "toggle" | "save";
} | null;

type ServiceActionState = {
  serviceId: number;
  type: "toggle" | "save";
} | null;

const emptyCategoryForm = {
  name: "",
  sortOrder: "0",
};

const emptyServiceForm = {
  categoryId: "",
  name: "",
  minPrice: "",
  maxPrice: "",
};

export function ServicesPanel({
  refreshToken,
  onMessage,
  onError,
}: ServicesPanelProps) {
  const [categories, setCategories] = useState<AdminCategory[]>([]);
  const [services, setServices] = useState<AdminService[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isCreatingCategory, setIsCreatingCategory] = useState(false);
  const [isCreatingService, setIsCreatingService] = useState(false);
  const [categoryActionState, setCategoryActionState] =
    useState<CategoryActionState>(null);
  const [serviceActionState, setServiceActionState] =
    useState<ServiceActionState>(null);
  const [categoryFilter, setCategoryFilter] = useState<string>("");
  const [createCategoryForm, setCreateCategoryForm] =
    useState(emptyCategoryForm);
  const [createServiceForm, setCreateServiceForm] = useState(emptyServiceForm);
  const [editingCategoryId, setEditingCategoryId] = useState<number | null>(
    null,
  );
  const [editCategoryForm, setEditCategoryForm] = useState(emptyCategoryForm);
  const [editCategoryIsActive, setEditCategoryIsActive] = useState(true);
  const [editingServiceId, setEditingServiceId] = useState<number | null>(null);
  const [editServiceForm, setEditServiceForm] = useState(emptyServiceForm);
  const [editServiceIsActive, setEditServiceIsActive] = useState(true);

  const activeCategories = useMemo(
    () => categories.filter((category) => category.is_active).length,
    [categories],
  );

  const activeServices = useMemo(
    () => services.filter((service) => service.is_active).length,
    [services],
  );

  async function reloadData() {
    onError("");
    setIsLoading(true);

    try {
      const [nextCategories, nextServices] = await Promise.all([
        loadCategories(),
        loadServices(
          categoryFilter ? Number.parseInt(categoryFilter, 10) : null,
        ),
      ]);
      setCategories(nextCategories);
      setServices(nextServices);
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    let cancelled = false;

    setIsLoading(true);
    onError("");

    Promise.all([
      loadCategories(),
      loadServices(categoryFilter ? Number.parseInt(categoryFilter, 10) : null),
    ])
      .then(([nextCategories, nextServices]) => {
        if (!cancelled) {
          setCategories(nextCategories);
          setServices(nextServices);
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
  }, [categoryFilter, onError, refreshToken]);

  async function handleCreateCategory(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    onError("");
    onMessage("");
    setIsCreatingCategory(true);

    try {
      await createCategory({
        name: createCategoryForm.name,
        sortOrder: Number.parseInt(createCategoryForm.sortOrder, 10) || 0,
      });
      setCreateCategoryForm(emptyCategoryForm);
      onMessage("تمت إضافة التخصص.");
      await reloadData();
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setIsCreatingCategory(false);
    }
  }

  async function handleCreateService(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    onError("");
    onMessage("");
    setIsCreatingService(true);

    try {
      await createService({
        categoryId: Number.parseInt(createServiceForm.categoryId, 10),
        name: createServiceForm.name,
        minPrice: Number.parseInt(createServiceForm.minPrice, 10),
        maxPrice: Number.parseInt(createServiceForm.maxPrice, 10),
      });
      setCreateServiceForm(emptyServiceForm);
      onMessage("تمت إضافة الخدمة.");
      await reloadData();
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setIsCreatingService(false);
    }
  }

  function startEditingCategory(category: AdminCategory) {
    setEditingCategoryId(category.id);
    setEditCategoryForm({
      name: category.name,
      sortOrder: String(category.sort_order),
    });
    setEditCategoryIsActive(category.is_active);
  }

  function startEditingService(service: AdminService) {
    setEditingServiceId(service.id);
    setEditServiceForm({
      categoryId: String(service.category_id),
      name: service.name,
      minPrice: String(service.min_price),
      maxPrice: String(service.max_price),
    });
    setEditServiceIsActive(service.is_active);
  }

  async function handleSaveCategory(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (editingCategoryId == null) {
      return;
    }

    onError("");
    onMessage("");
    setCategoryActionState({ categoryId: editingCategoryId, type: "save" });

    try {
      await updateCategory({
        categoryId: editingCategoryId,
        name: editCategoryForm.name,
        sortOrder: Number.parseInt(editCategoryForm.sortOrder, 10) || 0,
        isActive: editCategoryIsActive,
      });
      setEditingCategoryId(null);
      onMessage("تم تحديث التخصص.");
      await reloadData();
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setCategoryActionState(null);
    }
  }

  async function handleToggleCategory(category: AdminCategory) {
    onError("");
    onMessage("");
    setCategoryActionState({ categoryId: category.id, type: "toggle" });

    try {
      await updateCategory({
        categoryId: category.id,
        name: category.name,
        sortOrder: category.sort_order,
        isActive: !category.is_active,
      });
      onMessage(category.is_active ? "تم إخفاء التخصص." : "تم تفعيل التخصص.");
      await reloadData();
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setCategoryActionState(null);
    }
  }

  async function handleSaveService(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (editingServiceId == null) {
      return;
    }

    onError("");
    onMessage("");
    setServiceActionState({ serviceId: editingServiceId, type: "save" });

    try {
      await updateService({
        serviceId: editingServiceId,
        categoryId: Number.parseInt(editServiceForm.categoryId, 10),
        name: editServiceForm.name,
        minPrice: Number.parseInt(editServiceForm.minPrice, 10),
        maxPrice: Number.parseInt(editServiceForm.maxPrice, 10),
        isActive: editServiceIsActive,
      });
      setEditingServiceId(null);
      onMessage("تم تحديث الخدمة.");
      await reloadData();
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setServiceActionState(null);
    }
  }

  async function handleToggleService(service: AdminService) {
    onError("");
    onMessage("");
    setServiceActionState({ serviceId: service.id, type: "toggle" });

    try {
      await updateService({
        serviceId: service.id,
        categoryId: service.category_id,
        name: service.name,
        minPrice: service.min_price,
        maxPrice: service.max_price,
        isActive: !service.is_active,
      });
      onMessage(service.is_active ? "تم إخفاء الخدمة." : "تم تفعيل الخدمة.");
      await reloadData();
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setServiceActionState(null);
    }
  }

  return (
    <>
      <section className="stats-grid">
        <article className="stat-card">
          <span>التخصصات</span>
          <strong>{isLoading ? "..." : categories.length}</strong>
        </article>
        <article className="stat-card">
          <span>تخصصات نشطة</span>
          <strong>{isLoading ? "..." : activeCategories}</strong>
        </article>
        <article className="stat-card">
          <span>الخدمات المعروضة</span>
          <strong>{isLoading ? "..." : services.length}</strong>
        </article>
        <article className="stat-card">
          <span>خدمات نشطة</span>
          <strong>{isLoading ? "..." : activeServices}</strong>
        </article>
      </section>

      <section className="panel">
        <h2>التخصصات</h2>
        <p className="muted">
          اسم التخصص يجب أن يطابق مهنة الصنايعي حتى تظهر له الطلبات المناسبة.
        </p>

        <form className="form area-form" onSubmit={handleCreateCategory}>
          <label>
            اسم التخصص
            <input
              onChange={(event) =>
                setCreateCategoryForm((current) => ({
                  ...current,
                  name: event.target.value,
                }))
              }
              required
              value={createCategoryForm.name}
            />
          </label>
          <label>
            ترتيب العرض
            <input
              inputMode="numeric"
              onChange={(event) =>
                setCreateCategoryForm((current) => ({
                  ...current,
                  sortOrder: event.target.value,
                }))
              }
              type="number"
              value={createCategoryForm.sortOrder}
            />
          </label>
          <button className="primary-button" disabled={isCreatingCategory}>
            {isCreatingCategory ? "جاري الإضافة..." : "إضافة تخصص"}
          </button>
        </form>

        <div className="areas-list">
          {categories.map((category) => {
            const isEditing = editingCategoryId === category.id;
            const isBusy =
              categoryActionState?.categoryId === category.id &&
              Boolean(categoryActionState);

            if (isEditing) {
              return (
                <article className="worker-card" key={category.id}>
                  <form className="form" onSubmit={handleSaveCategory}>
                    <label>
                      اسم التخصص
                      <input
                        onChange={(event) =>
                          setEditCategoryForm((current) => ({
                            ...current,
                            name: event.target.value,
                          }))
                        }
                        required
                        value={editCategoryForm.name}
                      />
                    </label>
                    <label>
                      ترتيب العرض
                      <input
                        inputMode="numeric"
                        onChange={(event) =>
                          setEditCategoryForm((current) => ({
                            ...current,
                            sortOrder: event.target.value,
                          }))
                        }
                        type="number"
                        value={editCategoryForm.sortOrder}
                      />
                    </label>
                    <label className="checkbox-label">
                      <input
                        checked={editCategoryIsActive}
                        onChange={(event) =>
                          setEditCategoryIsActive(event.target.checked)
                        }
                        type="checkbox"
                      />
                      نشط في التطبيق
                    </label>
                    <div className="card-actions">
                      <button
                        className="primary-button"
                        disabled={Boolean(categoryActionState)}
                        type="submit"
                      >
                        {categoryActionState?.type === "save"
                          ? "جاري الحفظ..."
                          : "حفظ"}
                      </button>
                      <button
                        className="ghost-button"
                        onClick={() => setEditingCategoryId(null)}
                        type="button"
                      >
                        إلغاء
                      </button>
                    </div>
                  </form>
                </article>
              );
            }

            return (
              <article className="worker-card" key={category.id}>
                <div className="worker-header">
                  <div>
                    <h3>{category.name}</h3>
                    <p className="muted">
                      {category.active_service_count} خدمة نشطة من أصل{" "}
                      {category.service_count}
                    </p>
                  </div>
                  <span className="badge">
                    {category.is_active ? "نشط" : "مخفي"}
                  </span>
                </div>

                <div className="card-actions">
                  <button
                    className="secondary-button"
                    disabled={Boolean(categoryActionState)}
                    onClick={() => startEditingCategory(category)}
                    type="button"
                  >
                    تعديل
                  </button>
                  <button
                    className="secondary-button"
                    disabled={isBusy}
                    onClick={() => handleToggleCategory(category)}
                    type="button"
                  >
                    {categoryActionState?.type === "toggle"
                      ? "جاري التحديث..."
                      : category.is_active
                        ? "إخفاء"
                        : "تفعيل"}
                  </button>
                </div>
              </article>
            );
          })}
        </div>
      </section>

      <section className="panel panel-spacer">
        <div className="overview-list-header">
          <div>
            <h2>الخدمات</h2>
            <p className="muted">
              الخدمات النشطة فقط تظهر للعميل عند إنشاء الطلب.
            </p>
          </div>
          <label className="overview-status-filter">
            التخصص
            <select
              onChange={(event) => setCategoryFilter(event.target.value)}
              value={categoryFilter}
            >
              <option value="">الكل</option>
              {categories.map((category) => (
                <option key={category.id} value={String(category.id)}>
                  {category.name}
                </option>
              ))}
            </select>
          </label>
        </div>

        <form className="form area-form" onSubmit={handleCreateService}>
          <label>
            التخصص
            <select
              onChange={(event) =>
                setCreateServiceForm((current) => ({
                  ...current,
                  categoryId: event.target.value,
                }))
              }
              required
              value={createServiceForm.categoryId}
            >
              <option value="">اختر التخصص</option>
              {categories.map((category) => (
                <option key={category.id} value={String(category.id)}>
                  {category.name}
                </option>
              ))}
            </select>
          </label>
          <label>
            اسم الخدمة
            <input
              onChange={(event) =>
                setCreateServiceForm((current) => ({
                  ...current,
                  name: event.target.value,
                }))
              }
              required
              value={createServiceForm.name}
            />
          </label>
          <label>
            أقل سعر (جنيه)
            <input
              inputMode="numeric"
              onChange={(event) =>
                setCreateServiceForm((current) => ({
                  ...current,
                  minPrice: event.target.value,
                }))
              }
              required
              type="number"
              value={createServiceForm.minPrice}
            />
          </label>
          <label>
            أعلى سعر (جنيه)
            <input
              inputMode="numeric"
              onChange={(event) =>
                setCreateServiceForm((current) => ({
                  ...current,
                  maxPrice: event.target.value,
                }))
              }
              required
              type="number"
              value={createServiceForm.maxPrice}
            />
          </label>
          <button className="primary-button" disabled={isCreatingService}>
            {isCreatingService ? "جاري الإضافة..." : "إضافة خدمة"}
          </button>
        </form>

        <div className="areas-list">
          {isLoading ? (
            <p className="muted">جاري تحميل الخدمات...</p>
          ) : services.length === 0 ? (
            <p className="muted">لا توجد خدمات مطابقة.</p>
          ) : (
            services.map((service) => {
              const isEditing = editingServiceId === service.id;
              const isBusy =
                serviceActionState?.serviceId === service.id &&
                Boolean(serviceActionState);

              if (isEditing) {
                return (
                  <article className="worker-card" key={service.id}>
                    <form className="form" onSubmit={handleSaveService}>
                      <label>
                        التخصص
                        <select
                          onChange={(event) =>
                            setEditServiceForm((current) => ({
                              ...current,
                              categoryId: event.target.value,
                            }))
                          }
                          required
                          value={editServiceForm.categoryId}
                        >
                          {categories.map((category) => (
                            <option key={category.id} value={String(category.id)}>
                              {category.name}
                            </option>
                          ))}
                        </select>
                      </label>
                      <label>
                        اسم الخدمة
                        <input
                          onChange={(event) =>
                            setEditServiceForm((current) => ({
                              ...current,
                              name: event.target.value,
                            }))
                          }
                          required
                          value={editServiceForm.name}
                        />
                      </label>
                      <label>
                        أقل سعر
                        <input
                          inputMode="numeric"
                          onChange={(event) =>
                            setEditServiceForm((current) => ({
                              ...current,
                              minPrice: event.target.value,
                            }))
                          }
                          required
                          type="number"
                          value={editServiceForm.minPrice}
                        />
                      </label>
                      <label>
                        أعلى سعر
                        <input
                          inputMode="numeric"
                          onChange={(event) =>
                            setEditServiceForm((current) => ({
                              ...current,
                              maxPrice: event.target.value,
                            }))
                          }
                          required
                          type="number"
                          value={editServiceForm.maxPrice}
                        />
                      </label>
                      <label className="checkbox-label">
                        <input
                          checked={editServiceIsActive}
                          onChange={(event) =>
                            setEditServiceIsActive(event.target.checked)
                          }
                          type="checkbox"
                        />
                        نشطة في التطبيق
                      </label>
                      <div className="card-actions">
                        <button
                          className="primary-button"
                          disabled={Boolean(serviceActionState)}
                          type="submit"
                        >
                          {serviceActionState?.type === "save"
                            ? "جاري الحفظ..."
                            : "حفظ"}
                        </button>
                        <button
                          className="ghost-button"
                          onClick={() => setEditingServiceId(null)}
                          type="button"
                        >
                          إلغاء
                        </button>
                      </div>
                    </form>
                  </article>
                );
              }

              return (
                <article className="worker-card" key={service.id}>
                  <div className="worker-header">
                    <div>
                      <h3>{service.name}</h3>
                      <p className="muted">
                        {service.category_name} • {service.min_price}–
                        {service.max_price} جنيه
                      </p>
                    </div>
                    <span className="badge">
                      {service.is_active ? "نشطة" : "مخفية"}
                    </span>
                  </div>

                  <div className="card-actions">
                    <button
                      className="secondary-button"
                      disabled={Boolean(serviceActionState)}
                      onClick={() => startEditingService(service)}
                      type="button"
                    >
                      تعديل
                    </button>
                    <button
                      className="secondary-button"
                      disabled={isBusy}
                      onClick={() => handleToggleService(service)}
                      type="button"
                    >
                      {serviceActionState?.type === "toggle"
                        ? "جاري التحديث..."
                        : service.is_active
                          ? "إخفاء"
                          : "تفعيل"}
                    </button>
                  </div>
                </article>
              );
            })
          )}
        </div>
      </section>
    </>
  );
}

function getErrorMessage(error: unknown) {
  if (error instanceof Error) {
    if (error.message === "Admin access required") {
      return "ليس لديك صلاحية إدارية.";
    }

    return error.message;
  }

  return "حدث خطأ غير متوقع.";
}
