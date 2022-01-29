#!/usr/bin/perl -w
# Task:
#	- summarize and convert an HTML to XML
#
# Required non-standard Debian packages:
#   -  libxml-simple-perl
#
# Created by:	Kálmán Hadarics
# E-mail:	hadarics.kalman@gmail.com
# Version:	1.0
# Last mod.:	2008-02-10
#
# ----------------------------------------

use strict;
use utf8;
use open qw< :encoding(utf-8) >;
use XML::Simple;
use Data::Dumper;

=pod
sub LoadHTMLData()
    - Load HTML file data into a hash of arrays (HoA)

    Return:
        - reference to a HoA
=cut

sub LoadHTMLData() {
    my ($d,$r);
    open IN,"input.html";
    while(<IN>) {
        chomp;
        if (/^(.+)<ul>$/) {
            $d = $1;
            $r->{$d} = [];
        }
        elsif(/^.<li>([^:]+):([^:]+):([^:]+)$/) {
            push @{$r->{$d}},[$1,$2,$3];
        }
    }
    close IN;
    return $r;
}

=pod
sub ProcessandOutputData

    - Process input data structure (HoA) and create XML output
=cut

sub ProcessandOutputData {

=pod
sub OutputXML

    - Create XML output

    Params:
        $_[1]: reference to an XML::Simple object
        $_[2]: reference to a HASH
=cut

    sub OutputXML($$)  {
        my ($pxs, $pref) = @_;
        my $xml = $pxs->XMLout($pref, RootName => 'summary', NoAttr => 1, XMLDecl => '<?xml version="1.0" encoding="utf-8"?>');

        open OUT, ">output.xml";
        print OUT $xml;
        close OUT
    }

    my $d = shift;
    my %o = ();
    foreach (keys %$d) {
        foreach my $i (@{$d->{$_}}) {
            if (!exists($o{$i->[0]})) {
                $o{$i->[0]} = $i->[1]*$i->[2];
            }
            else {
                $o{$i->[0]} += $i->[1]*$i->[2];
            }
        }
    }

    my $xs = new XML::Simple(KeepRoot => 0, SearchPath => ".", KeyAttr =>'name');
    my $ref = $xs->XMLin("<summary></summary>");

    foreach (sort { $o{$a} <=> $o{$b} } keys(%o)) {
        $ref->{'item'}->{$_} = {"sum" => sprintf("%.2f", $o{$_})};
    }

    OutputXML($xs, $ref)
}

my $data = &LoadHTMLData;
# print Dumper($data);
&ProcessandOutputData($data);