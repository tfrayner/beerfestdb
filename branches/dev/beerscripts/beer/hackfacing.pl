while (<>) {
	chomp;
	my @fields = split (':', $_);
	my ($id, $size, $brewery, $beer, $abv, $supplier, $cbay, $crow, $cpos, $facing, $xs, $ys) = @fields;
	push @casks, [@fields];
	next if $brewery eq "(space)";
	next if $brewery eq "Cooler";
	$pos{$cbay}{$crow}{$cpos}++;
}

foreach (@casks) {
	my ($id, $size, $brewery, $beer, $abv, $supplier, $cbay, $crow, $cpos, $facing, $xs, $ys) = @$_;
	
	$facing = "Facing Front";
	$facing = "Facing Back" if ($crow eq "ub");
	$facing = "Facing Back" if ($crow eq "lb" && ! exists $pos{$cbay}{'lm'}{$cpos});
	print join (':', $id, $size, $brewery, $beer, $abv, $supplier, $cbay, $crow, $cpos, $facing, $xs, $ys);
	print "\n";
}
