from rest_framework import routers
from django.urls import path, include

from . import views

router = routers.DefaultRouter()

# register all viewsets with the router
router.register(r'festivals', views.FestivalViewSet)
router.register(r'company-regions', views.CompanyRegionViewSet)
router.register(r'companies', views.CompanyViewSet)
router.register(r'product-categories', views.ProductCategoryViewSet)
router.register(r'product-styles', views.ProductStyleViewSet)
router.register(r'products', views.ProductViewSet)
router.register(r'bars', views.BarViewSet)
router.register(r'bay-positions', views.BayPositionViewSet)
router.register(r'container-measures', views.ContainerMeasureViewSet)
router.register(r'dispense-methods', views.DispenseMethodViewSet)
router.register(r'container-sizes', views.ContainerSizeViewSet)
router.register(r'order-batches', views.OrderBatchViewSet)
router.register(r'currencies', views.CurrencyViewSet)
router.register(r'product-orders', views.ProductOrderViewSet)
router.register(r'sale-volumes', views.SaleVolumeViewSet)
router.register(r'festival-products', views.FestivalProductViewSet)
router.register(r'gyles', views.GyleViewSet)
router.register(r'stillage-locations', views.StillageLocationViewSet)
router.register(r'cask-management', views.CaskManagementViewSet)
router.register(r'casks', views.CaskViewSet)
router.register(r'measurement-batches', views.MeasurementBatchViewSet)
router.register(r'cask-measurements', views.CaskMeasurementViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
