#
# Copyright (C) 1999 Ken MacLeod
# XML::PatAct::Amsterdam is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Amsterdam.pm,v 1.1 1999/08/10 21:42:39 kmacleod Exp $
#

use strict;

use UNIVERSAL;

package XML::PatAct::Amsterdam;

sub new {
    my $type = shift; my $self = { @_ };

    bless $self, $type;

    my $usage = <<'EOF';
usage: XML::PatAct::Amsterdam->new( Matcher => $matcher,
				 Patterns => $patterns );
EOF

    die "No Matcher specified\n$usage\n"
	if !defined $self->{Matcher};
    die "No Patterns specified\n$usage\n"
	if !defined $self->{Patterns};

    # perform additional initialization here

    return $self;
}

sub start_document {
    my ($self, $document) = @_;

    # initialize the pattern module at the start of a document
    $self->{Matcher}->initialize($self);

    # create empty name and node lists for passing to `match()'
    $self->{Names} = [ ];
    $self->{Nodes} = [ ];

    $self->{ActionStack} = [ ];

    if (!defined $self->{File}) {
	require IO::File;
	import IO::File;
	$self->{File} = IO::File->new('>-');
	$self->{DeleteFile} = 1;
    }
}

sub end_document {
    my ($self, $document) = @_;

    # notify the pattern module that we're done
    $self->{Matcher}->finalize();

    my $value;
    if ($self->{DeleteFile}) {
	$self->{File} = $self->{DeleteFile} = undef;
    }

    # release all the info that is just used during event handling
    $self->{Matcher} = $self->{Names} = $self->{Nodes} = undef;
    $self->{ActionStack} = undef;

    return $value;
}

sub start_element {
    my ($self, $element) = @_;

    push @{$self->{Names}}, $element->{Name};
    push @{$self->{Nodes}}, $element;

    my $index = $self->{Matcher}->match($element,
					$self->{Names},
					$self->{Nodes});

    my $action;
    if (!defined $index) {
	$action = undef;
    } else {
	$action = $self->{Patterns}[$index * 2 + 1];
    }

    push @{$self->{ActionStack}}, $action;

    if (defined($action) && defined($action->{Before})) {
	$self->{File}->print($action->{Before});
    }
}

sub end_element {
    my ($self, $end_element) = @_;

    my $name = pop @{$self->{Names}};
    my $element = pop @{$self->{Nodes}};

    my $action = pop @{$self->{ActionStack}};

    if (defined($action) && defined($action->{After})) {
	$self->{File}->print($action->{After});
    }
}

sub characters {
    my ($self, $characters) = @_;

    $self->{File}->print($characters->{Data});
}

1;

__END__

=head1 NAME

XML::PatAct::Amsterdam - An action module for simplistic style-sheets

=head1 SYNOPSIS

 use XML::PatAct::Amsterdam;

 my $patterns = [ PATTERN => { Before => 'before',
			       After => 'after' },
		  ... ];

 my $matcher = XML::PatAct::Amsterdam->new( Patterns => $patterns,
					    Matcher => $matcher,
					    File => $file );


=head1 DESCRIPTION

XML::PatAct::Amsterdam is a PerlSAX handler for applying
pattern-action lists to XML parses or trees.  XML::PatAct::Amsterdam
applies a very simple style sheet to an instance and outputs the
result.  Amsterdam gets it's name from the Amsterdam SGML Parser (ASP)
which inspired this module.

CAUTION: Amsterdam is a very simple style module, you will run into
it's limitations quickly with even moderately complex XML instances,
be aware of and prepared to switch to more complete style modules.

New XML::PatAct::Amsterdam instances are creating by calling `new()'.
A Patterns and Matcher options are required.  Patterns is the
pattern-action list to apply.  Matcher is an instance of the pattern
or query matching module.  The File option is an open io handle (see
IO::Handle) to write to, if the File option is missing, Amsterdam
defaults to writing to standard output.

Each action in Amsterdam contains either or both a Before and an After
string to copy to the output before and after processing an XML
element.

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1)

``Using PatAct Modules'' and ``Creating PatAct Modules'' in libxml-perl.

=cut
