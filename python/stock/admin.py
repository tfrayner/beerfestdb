from django.contrib import admin
from . import models


@admin.register(models.Festival)
class FestivalAdmin(admin.ModelAdmin):
	list_display = ('id', 'name', 'year')
	search_fields = ('name',)


@admin.register(models.CompanyRegion)
class CompanyRegionAdmin(admin.ModelAdmin):
	list_display = ('id', 'description')


@admin.register(models.Company)
class CompanyAdmin(admin.ModelAdmin):
	list_display = ('id', 'name', 'company_region')
	search_fields = ('name',)


@admin.register(models.ProductCategory)
class ProductCategoryAdmin(admin.ModelAdmin):
	list_display = ('id', 'description')


@admin.register(models.ProductStyle)
class ProductStyleAdmin(admin.ModelAdmin):
	list_display = ('id', 'description', 'product_category')
	search_fields = ('description',)


@admin.register(models.Product)
class ProductAdmin(admin.ModelAdmin):
	list_display = ('id', 'name', 'company', 'product_category', 'product_style')
	search_fields = ('name',)
	list_filter = ('product_category', 'company')


@admin.register(models.Bar)
class BarAdmin(admin.ModelAdmin):
	list_display = ('id', 'description', 'festival')
	search_fields = ('description',)


@admin.register(models.BayPosition)
class BayPositionAdmin(admin.ModelAdmin):
	list_display = ('id', 'description')


@admin.register(models.ContainerMeasure)
class ContainerMeasureAdmin(admin.ModelAdmin):
	list_display = ('id', 'description', 'symbol')


@admin.register(models.DispenseMethod)
class DispenseMethodAdmin(admin.ModelAdmin):
	list_display = ('id', 'description', 'is_disposable')


@admin.register(models.ContainerSize)
class ContainerSizeAdmin(admin.ModelAdmin):
	list_display = ('id', 'description', 'container_volume', 'container_measure', 'dispense_method')
	search_fields = ('description',)


@admin.register(models.OrderBatch)
class OrderBatchAdmin(admin.ModelAdmin):
	list_display = ('id', 'description', 'festival', 'order_date')


@admin.register(models.Currency)
class CurrencyAdmin(admin.ModelAdmin):
	list_display = ('id', 'currency_code', 'currency_symbol')
	search_fields = ('currency_code',)


@admin.register(models.ProductOrder)
class ProductOrderAdmin(admin.ModelAdmin):
	list_display = ('id', 'order_batch', 'product', 'distributor_company', 'cask_count', 'is_final')
	list_filter = ('is_final', 'is_received')


@admin.register(models.SaleVolume)
class SaleVolumeAdmin(admin.ModelAdmin):
	list_display = ('id', 'description', 'volume')


@admin.register(models.FestivalProduct)
class FestivalProductAdmin(admin.ModelAdmin):
	list_display = ('id', 'festival', 'product', 'sale_price')


@admin.register(models.Gyle)
class GyleAdmin(admin.ModelAdmin):
	list_display = ('id', 'internal_reference', 'company', 'festival_product')
	search_fields = ('internal_reference',)


@admin.register(models.StillageLocation)
class StillageLocationAdmin(admin.ModelAdmin):
	list_display = ('id', 'festival', 'description')


@admin.register(models.CaskManagement)
class CaskManagementAdmin(admin.ModelAdmin):
	list_display = ('id', 'festival', 'cellar_reference', 'container_size', 'bar', 'price')
	list_filter = ('festival', 'bar')


@admin.register(models.Cask)
class CaskAdmin(admin.ModelAdmin):
	list_display = ('id', 'cask_management', 'gyle', 'is_condemned', 'is_tapped', 'is_ready')


@admin.register(models.MeasurementBatch)
class MeasurementBatchAdmin(admin.ModelAdmin):
	list_display = ('id', 'festival', 'measurement_time')


@admin.register(models.CaskMeasurement)
class CaskMeasurementAdmin(admin.ModelAdmin):
	list_display = ('id', 'cask', 'measurement_batch', 'volume')
