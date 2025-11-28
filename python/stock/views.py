from rest_framework import viewsets

from . import models
from . import serializers


# Create a ModelViewSet for each model so the API provides full CRUD access.
class FestivalViewSet(viewsets.ModelViewSet):
	queryset = models.Festival.objects.all()
	serializer_class = serializers.FestivalSerializer


class CompanyRegionViewSet(viewsets.ModelViewSet):
	queryset = models.CompanyRegion.objects.all()
	serializer_class = serializers.CompanyRegionSerializer


class CompanyViewSet(viewsets.ModelViewSet):
	queryset = models.Company.objects.all()
	serializer_class = serializers.CompanySerializer


class ProductCategoryViewSet(viewsets.ModelViewSet):
	queryset = models.ProductCategory.objects.all()
	serializer_class = serializers.ProductCategorySerializer


class ProductStyleViewSet(viewsets.ModelViewSet):
	queryset = models.ProductStyle.objects.all()
	serializer_class = serializers.ProductStyleSerializer


class ProductViewSet(viewsets.ModelViewSet):
	queryset = models.Product.objects.all()
	serializer_class = serializers.ProductSerializer


class BarViewSet(viewsets.ModelViewSet):
	queryset = models.Bar.objects.all()
	serializer_class = serializers.BarSerializer


class BayPositionViewSet(viewsets.ModelViewSet):
	queryset = models.BayPosition.objects.all()
	serializer_class = serializers.BayPositionSerializer


class ContainerMeasureViewSet(viewsets.ModelViewSet):
	queryset = models.ContainerMeasure.objects.all()
	serializer_class = serializers.ContainerMeasureSerializer


class DispenseMethodViewSet(viewsets.ModelViewSet):
	queryset = models.DispenseMethod.objects.all()
	serializer_class = serializers.DispenseMethodSerializer


class ContainerSizeViewSet(viewsets.ModelViewSet):
	queryset = models.ContainerSize.objects.all()
	serializer_class = serializers.ContainerSizeSerializer


class OrderBatchViewSet(viewsets.ModelViewSet):
	queryset = models.OrderBatch.objects.all()
	serializer_class = serializers.OrderBatchSerializer


class CurrencyViewSet(viewsets.ModelViewSet):
	queryset = models.Currency.objects.all()
	serializer_class = serializers.CurrencySerializer


class ProductOrderViewSet(viewsets.ModelViewSet):
	queryset = models.ProductOrder.objects.all()
	serializer_class = serializers.ProductOrderSerializer


class SaleVolumeViewSet(viewsets.ModelViewSet):
	queryset = models.SaleVolume.objects.all()
	serializer_class = serializers.SaleVolumeSerializer


class FestivalProductViewSet(viewsets.ModelViewSet):
	queryset = models.FestivalProduct.objects.all()
	serializer_class = serializers.FestivalProductSerializer


class GyleViewSet(viewsets.ModelViewSet):
	queryset = models.Gyle.objects.all()
	serializer_class = serializers.GyleSerializer


class StillageLocationViewSet(viewsets.ModelViewSet):
	queryset = models.StillageLocation.objects.all()
	serializer_class = serializers.StillageLocationSerializer


class CaskManagementViewSet(viewsets.ModelViewSet):
	queryset = models.CaskManagement.objects.all()
	serializer_class = serializers.CaskManagementSerializer


class CaskViewSet(viewsets.ModelViewSet):
	queryset = models.Cask.objects.all()
	serializer_class = serializers.CaskSerializer


class MeasurementBatchViewSet(viewsets.ModelViewSet):
	queryset = models.MeasurementBatch.objects.all()
	serializer_class = serializers.MeasurementBatchSerializer


class CaskMeasurementViewSet(viewsets.ModelViewSet):
	queryset = models.CaskMeasurement.objects.all()
	serializer_class = serializers.CaskMeasurementSerializer
