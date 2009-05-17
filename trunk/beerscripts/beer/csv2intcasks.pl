#!/usr/bin/perl

# convert a CSV a la Dave Hughes to a Steve Early casklist

# input:
#Bar	Brewery	Beer	ABV	Style	No	Size	Kils	Supplier
# Cambridge	Cambridge Moonshine	Mulberry Whale	3.90%	Bitter	6	9	3	Brewery
# output:
# Caskid Casksize Brewery Beer ABV Collection Bay Row Position
#100::9::Young's::Double Chocolate::5.2::Beer Seller::::::

$id=100;

while(<>) {
	chomp;
	my ($bar, $brewery, $beer, $abv, $style, $no, $size, $kils, $supplier) = split(',');
	$brewery ||= $lastbrewery;
	$lastbrewery = $brewery;
	for (1..$no) {
		print join (':', $id++, $size, $brewery, $beer, $abv, $supplier, undef, undef, undef, undef);
		print "\n";
	}
}
