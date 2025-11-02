from django.db import models

class Festival(models.Model):
    year = models.IntegerField()
    name = models.CharField(max_length=60, unique=True)
    description = models.TextField(blank=True, null=True)
    fst_start_date = models.DateField(blank=True, null=True)
    fst_end_date = models.DateField(blank=True, null=True)

    def __str__(self):
        return self.name

class CompanyRegion(models.Model):
    description = models.CharField(max_length=30, unique=True)

    def __str__(self):
        return self.description

class Company(models.Model):
    name = models.CharField(max_length=100, unique=True)
    full_name = models.CharField(max_length=255, blank=True, null=True)
    loc_desc = models.CharField(max_length=100, blank=True, null=True)
    company_region = models.ForeignKey(CompanyRegion, on_delete=models.SET_NULL, null=True)
    year_founded = models.IntegerField(blank=True, null=True)
    url = models.URLField(max_length=255, blank=True, null=True)
    awrs_urn = models.CharField(max_length=31, blank=True, null=True)
    comment = models.TextField(blank=True, null=True)

    def __str__(self):
        return self.name

class ProductCategory(models.Model):
    description = models.CharField(max_length=100, unique=True)

    def __str__(self):
        return self.description

class ProductStyle(models.Model):
    product_category = models.ForeignKey(ProductCategory, on_delete=models.CASCADE)
    description = models.CharField(max_length=100)

    class Meta:
        unique_together = ['product_category', 'description']

    def __str__(self):
        return self.description

class Product(models.Model):
    company = models.ForeignKey(Company, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    product_category = models.ForeignKey(ProductCategory, on_delete=models.PROTECT)
    product_style = models.ForeignKey(ProductStyle, on_delete=models.SET_NULL, null=True)
    nominal_abv = models.DecimalField(max_digits=3, decimal_places=1, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    long_description = models.TextField(blank=True, null=True)
    comment = models.TextField(blank=True, null=True)

    class Meta:
        unique_together = ['company', 'name']

    def __str__(self):
        return f"{self.company.name} - {self.name}"

class Bar(models.Model):
    festival = models.ForeignKey(Festival, on_delete=models.CASCADE)
    description = models.CharField(max_length=255, unique=True)
    is_private = models.BooleanField(blank=True, null=True)

    def __str__(self):
        return self.description

class BayPosition(models.Model):
    description = models.CharField(max_length=50, unique=True)

    def __str__(self):
        return self.description

class ContainerMeasure(models.Model):
    litre_multiplier = models.DecimalField(max_digits=15, decimal_places=12)
    description = models.CharField(max_length=50, unique=True)
    symbol = models.CharField(max_length=16)

    def __str__(self):
        return self.description

class DispenseMethod(models.Model):
    description = models.CharField(max_length=100, unique=True)
    is_disposable = models.BooleanField(default=False)

    def __str__(self):
        return self.description

class ContainerSize(models.Model):
    container_volume = models.DecimalField(max_digits=4, decimal_places=2)
    container_measure = models.ForeignKey(ContainerMeasure, on_delete=models.PROTECT)
    dispense_method = models.ForeignKey(DispenseMethod, on_delete=models.PROTECT)
    description = models.CharField(max_length=100, unique=True)

    class Meta:
        unique_together = ['container_volume', 'container_measure', 'dispense_method']

    def __str__(self):
        return self.description

class OrderBatch(models.Model):
    festival = models.ForeignKey(Festival, on_delete=models.PROTECT)
    description = models.CharField(max_length=255)
    order_date = models.DateField(blank=True, null=True)

    class Meta:
        unique_together = ['festival', 'description']

    def __str__(self):
        return f"{self.festival.name} - {self.description}"

class Currency(models.Model):
    currency_code = models.CharField(max_length=3, unique=True)
    currency_number = models.CharField(max_length=3)
    currency_format = models.CharField(max_length=20)
    exponent = models.SmallIntegerField()
    currency_symbol = models.CharField(max_length=10)

    def __str__(self):
        return self.currency_code

class ProductOrder(models.Model):
    order_batch = models.ForeignKey(OrderBatch, on_delete=models.PROTECT)
    product = models.ForeignKey(Product, on_delete=models.PROTECT)
    distributor_company = models.ForeignKey(Company, on_delete=models.PROTECT)
    container_size = models.ForeignKey(ContainerSize, on_delete=models.PROTECT)
    cask_count = models.PositiveIntegerField()
    currency = models.ForeignKey(Currency, on_delete=models.PROTECT)
    advertised_price = models.PositiveIntegerField(blank=True, null=True)
    is_final = models.BooleanField(blank=True, null=True)
    is_received = models.BooleanField(blank=True, null=True)
    comment = models.TextField(blank=True, null=True)
    is_sale_or_return = models.BooleanField(default=False)

    class Meta:
        unique_together = ['order_batch', 'product', 'distributor_company', 'container_size', 
                         'cask_count', 'is_sale_or_return']

    def __str__(self):
        return f"{self.product.name} - {self.cask_count} x {self.container_size.description}"

class SaleVolume(models.Model):
    container_measure = models.ForeignKey(ContainerMeasure, on_delete=models.PROTECT)
    description = models.CharField(max_length=30, unique=True)
    volume = models.DecimalField(max_digits=4, decimal_places=2)

    def __str__(self):
        return self.description

class FestivalProduct(models.Model):
    festival = models.ForeignKey(Festival, on_delete=models.CASCADE)
    sale_volume = models.ForeignKey(SaleVolume, on_delete=models.PROTECT)
    sale_currency = models.ForeignKey(Currency, on_delete=models.PROTECT)
    sale_price = models.PositiveIntegerField(blank=True, null=True)
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    comment = models.TextField(blank=True, null=True)

    class Meta:
        unique_together = ['festival', 'product']

    def __str__(self):
        return f"{self.festival.name} - {self.product.name}"

class Gyle(models.Model):
    company = models.ForeignKey(Company, on_delete=models.PROTECT)
    festival_product = models.ForeignKey(FestivalProduct, on_delete=models.PROTECT)
    abv = models.DecimalField(max_digits=3, decimal_places=1, blank=True, null=True)
    comment = models.TextField(blank=True, null=True)
    external_reference = models.CharField(max_length=255, blank=True, null=True)
    internal_reference = models.CharField(max_length=255)

    class Meta:
        unique_together = ['festival_product', 'internal_reference']

    def __str__(self):
        return f"{self.festival_product.product.name} - {self.internal_reference}"

class StillageLocation(models.Model):
    festival = models.ForeignKey(Festival, on_delete=models.PROTECT)
    description = models.CharField(max_length=50)

    class Meta:
        unique_together = ['festival', 'description']

    def __str__(self):
        return self.description

class CaskManagement(models.Model):
    festival = models.ForeignKey(Festival, on_delete=models.PROTECT)
    distributor_company = models.ForeignKey(Company, on_delete=models.SET_NULL, null=True, related_name='distributed_casks')
    product_order = models.ForeignKey(ProductOrder, on_delete=models.CASCADE, null=True)
    container_size = models.ForeignKey(ContainerSize, on_delete=models.PROTECT)
    bar = models.ForeignKey(Bar, on_delete=models.SET_NULL, null=True)
    currency = models.ForeignKey(Currency, on_delete=models.PROTECT)
    price = models.PositiveIntegerField(blank=True, null=True)
    stillage_location = models.ForeignKey(StillageLocation, on_delete=models.SET_NULL, null=True)
    stillage_bay = models.PositiveIntegerField(blank=True, null=True)
    bay_position = models.ForeignKey(BayPosition, on_delete=models.SET_NULL, null=True)
    stillage_x_location = models.PositiveIntegerField(blank=True, null=True)
    stillage_y_location = models.PositiveIntegerField(blank=True, null=True)
    stillage_z_location = models.PositiveIntegerField(blank=True, null=True)
    internal_reference = models.IntegerField(blank=True, null=True)
    cellar_reference = models.IntegerField()
    is_sale_or_return = models.BooleanField(default=False)

    class Meta:
        unique_together = ['festival', 'cellar_reference']

    def __str__(self):
        return f"Cask {self.cellar_reference} at {self.festival.name}"

class Cask(models.Model):
    gyle = models.ForeignKey(Gyle, on_delete=models.PROTECT)
    comment = models.TextField(blank=True, null=True)
    external_reference = models.CharField(max_length=255, blank=True, null=True)
    is_vented = models.BooleanField(blank=True, null=True)
    is_tapped = models.BooleanField(blank=True, null=True)
    is_ready = models.BooleanField(blank=True, null=True)
    is_condemned = models.BooleanField(default=False)
    cask_management = models.OneToOneField(CaskManagement, on_delete=models.PROTECT)

    def __str__(self):
        return f"Cask {self.cask_management.cellar_reference} - {self.gyle.festival_product.product.name}"

class MeasurementBatch(models.Model):
    festival = models.ForeignKey(Festival, on_delete=models.PROTECT)
    measurement_time = models.DateTimeField()
    description = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        unique_together = ['festival', 'measurement_time']

    def __str__(self):
        return f"{self.festival.name} - {self.measurement_time}"

class CaskMeasurement(models.Model):
    cask = models.ForeignKey(Cask, on_delete=models.PROTECT)
    measurement_batch = models.ForeignKey(MeasurementBatch, on_delete=models.PROTECT)
    volume = models.DecimalField(max_digits=5, decimal_places=2)
    container_measure = models.ForeignKey(ContainerMeasure, on_delete=models.PROTECT)
    comment = models.TextField(blank=True, null=True)

    class Meta:
        unique_together = ['cask', 'measurement_batch']

    def __str__(self):
        return f"{self.cask} - {self.volume} {self.container_measure.symbol}"