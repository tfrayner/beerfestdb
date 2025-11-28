from rest_framework import serializers
from . import models

# Generate a ModelSerializer for every model in stock.models

class FestivalSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Festival
        fields = '__all__'

class CompanyRegionSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.CompanyRegion
        fields = '__all__'

class CompanySerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Company
        fields = '__all__'

class ProductCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = models.ProductCategory
        fields = '__all__'

class ProductStyleSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.ProductStyle
        fields = '__all__'

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Product
        fields = '__all__'

class BarSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Bar
        fields = '__all__'

class BayPositionSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.BayPosition
        fields = '__all__'

class ContainerMeasureSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.ContainerMeasure
        fields = '__all__'

class DispenseMethodSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.DispenseMethod
        fields = '__all__'

class ContainerSizeSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.ContainerSize
        fields = '__all__'

class OrderBatchSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.OrderBatch
        fields = '__all__'

class CurrencySerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Currency
        fields = '__all__'

class ProductOrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.ProductOrder
        fields = '__all__'

class SaleVolumeSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.SaleVolume
        fields = '__all__'

class FestivalProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.FestivalProduct
        fields = '__all__'

class GyleSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Gyle
        fields = '__all__'

class StillageLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.StillageLocation
        fields = '__all__'

class CaskManagementSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.CaskManagement
        fields = '__all__'

class CaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Cask
        fields = '__all__'

class MeasurementBatchSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.MeasurementBatch
        fields = '__all__'

class CaskMeasurementSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.CaskMeasurement
        fields = '__all__'
