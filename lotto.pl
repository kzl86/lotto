#!/usr/bin/perl

use strict;
use warnings;

my $banner = <<'END_BANNER';
+-----------------------------------------------------------------------------+
|  LOTTÓ ELLENŐRZŐ                                                            |
|                                                                             |
|   Támogatott lottók:                                                        |
|    - Ötöslottó                                                              |
|    - Hatoslottó                                                             |
|    - Skandináv lottó                                                        |
|    - Joker                                                                  |
|                                                                             |
+-----------------------------------------------------------------------------+
Használat:
 - Játékonként számok bevitele <SPACE> elválasztásával, majd <ENTER>.
 - A kiértékelés üres sor + <ENTER> esetén indul.
 - A játékok tetszőleges sorrendben megadhatóak.
 - A számok között tetszőleges számú space karakter lehet.
 - A csillaggal jelölt sor hibaüzenet, amely jelzi,
   hogy a legutolsó bevitt sor nem került feldolgozásra.
 - Megszakításhoz <CTRL> + <C> a program bármely pontján.

END_BANNER
print $banner;

# Download ahead

my $possibility = 0;
`wget -q https://bet.szerencsejatek.hu/cmsfiles/otos.html -O otos.html`; if (-e 'otos.html') { $possibility += 1 }
`wget -q https://bet.szerencsejatek.hu/cmsfiles/hatos.html -O hatos.html`; if (-e 'hatos.html') { $possibility += 2 }
`wget -q https://bet.szerencsejatek.hu/cmsfiles/skandi.html -O skandi.html`; if (-e 'skandi.html') { $possibility += 4 }

my $prompt;

SWITCH : {
  ( $possibility == 1) && do { print "A Hatoslottó és a Skandináv lottó eredménye nincs letöltve!\n"; $prompt = "ÖTÖS> "; last SWITCH };
  ( $possibility == 2) && do { print "Az Ötöslottó és a Skandináv lottó eredménye nincs letöltve!\n"; $prompt = "HATOS> "; last SWITCH };
  ( $possibility == 3) && do { print "A Skandináv lottó eredménye nincs letöltve!\n"; $prompt = "ÖTÖS/HATOS> "; last SWITCH };
  ( $possibility == 4) && do { print "Az Ötöslottó és a Hatoslottó eredménye nincs letöltve!\n"; $prompt = "SKANDI> "; last SWITCH };
  ( $possibility == 5) && do { print "A Hatoslottó eredménye nincs letöltve!\n"; $prompt = "ÖTÖS/SKANDI> "; last SWITCH };
  ( $possibility == 6) && do { print "Az Ötöslottó eredménye nincs letöltve!\n"; $prompt = "HATOS/SKANDI> "; last SWITCH };
  ( $possibility == 7) && do { $prompt = "ÖTÖS/HATOS/SKANDI> "; last SWITCH };
}

# Fill up the matrix.

my $fullreport = '';
my @matrix;

if ( $possibility > 0 ) {

  print $prompt;
  while (<STDIN>) {
    $_ =~ s/^\s+|\s+$//g;
    $_ =~ s/\s+/ /g;
    last unless $_;
    my $error = syntax_check ($_);
    if ($error ne '') { print $error } else { push @matrix, $_ }
    print $prompt;
  }
  @matrix = sort { length $a <=> length $b } @matrix;

  # Determine games.

  my %games = (
    '5' => 'NOT_CHOOSEN',
    '6' => 'NOT_CHOOSEN',
    '7' => 'NOT_CHOOSEN'
  );

  foreach my $line (@matrix) {
    my @numbers = split " ", $line;
    if ( scalar @numbers == 5 ) { $games { '5' } = 'CHOOSEN' }
    if ( scalar @numbers == 6 ) { $games { '6' } = 'CHOOSEN' }
    if ( scalar @numbers == 7 ) { $games { '7' } = 'CHOOSEN' }
  }

  # Create full report with the help of sub methods.

  foreach my $line (@matrix) {

    my @numbers = split " ", $line;

    if ( scalar @numbers == 5 ) {
      if ( $games { '5' } eq 'CHOOSEN' ) {
        $fullreport .= five_header();
        $fullreport .= five(\@numbers);
        $games { '5' } = 'HEADER';
      } elsif (-e 'otos.html') {
        $fullreport .= five(\@numbers);
      }
    }

    if ( scalar @numbers == 6 ) {
      if ($games { '6' } eq 'CHOOSEN') {
        $fullreport .= six_header();
        $fullreport .= six(\@numbers);
        $games { '6' } = 'HEADER';
      } elsif (-e 'hatos.html') {
        $fullreport .= six(\@numbers);
      }
    }

    if ( scalar @numbers == 7 ) {
      if ($games {'7'} eq 'CHOOSEN') {
        $fullreport .= seven_header();
        $fullreport .= seven(\@numbers);
        $games { '7' } = 'HEADER'
      } elsif (-e 'skandi.html') {
        $fullreport .= seven(\@numbers);
      }
    }
  }
} else {
  print "Az Ötöslottó, Hatoslottó és a Skandináv lottó eredménye nincs letöltve!\n";
}

# Cleanup.

if ( -e 'otos.html' ) { `rm otos.html` }
if ( -e 'hatos.html' ) { `rm hatos.html` }
if ( -e 'skandi.html' ) { `rm skandi.html`}

# Extend full report with the Joker game.

`wget -q https://bet.szerencsejatek.hu/cmsfiles/joker.html -O joker.html`;

if (-e 'joker.html' and scalar @matrix >= 1) {
my $key;
do {
  print "Joker? (i)gen / (n)em\n";
  open(TTY, "+</dev/tty") or die "no tty: $!";
  system "stty -echo cbreak </dev/tty >/dev/tty 2>&1";
  sysread(TTY, $key, 1);
  system "stty echo -cbreak </dev/tty >/dev/tty 2>&1";
} until ( ($key eq 'i') or ($key eq 'n') );

if ($key eq 'i') {

  print "JOKER> ";
  my @joker_matrix;
  while (<STDIN>) {
    $_ =~ s/^\s+|\s+$//g;
    $_ =~ s/\s+/ /g;
    last unless $_;
    my $error = syntax_check_joker ($_);
    if ($error ne '') { print $error } else { push @joker_matrix, $_ }
    print "JOKER> ";
  }


    $fullreport .= joker_header();
    foreach my $line (@joker_matrix) {
      my @numbers;
      if ( $line =~ /\d{6}/) { @numbers = split //, $line } else {
        @numbers = split / /, $line
      }
      $fullreport .= joker(\@numbers);
    }
    `rm joker.html`;
  }
} else {
  print "A Joker sorsolás eredménye nincs letöltve!\n" if (scalar @matrix >= 1);
}

# Print results:
$fullreport .= "\n";
print $fullreport;

# End of main program, sub methods.

sub nmf { # stands for 'new money format'
  my $old_format = shift;
  my $new_format;
  if ($old_format =~ /(.+)Ft/) {
    $new_format = $1;
    $new_format =~ s/ /,/g;
  }
  $new_format .= '- Ft'
}

sub syntax_check {
  my $line = shift;
  my @numbers = split / /, $line;

  my $error = '';

  my $toomany = 0;
  my $not_enough = 0;
  my $not_number = 0;

  if (scalar @numbers > 7) { $toomany = 1 }
  if (scalar @numbers < 5) { $not_enough = 1}
  foreach (@numbers) {
    if ($_ =~ /\D+/) { $not_number = 1 }
  }

  SWITCH : {
    ( $toomany && $not_number ) && do { $error .= " * \'$line\' - túl sok elem / nem szám!\n"; last SWITCH };
    ( $not_enough && $not_number) && do { $error .= " * \'$line\' - túl kevés elem / nem szám!\n"; last SWITCH};
    ( $toomany ) && do { $error .= " * \'$line\' - túl sok szám!\n"; last SWITCH };
    ( $not_number ) && do { $error .= " * \'$line\' - nem szám!\n"; last SWITCH };
    ( $not_enough ) && do { $error .= " * \'$line\' - túl kevés szám!\n"; last SWITCH }
  }

  if ($error eq '') {
    if ( scalar @numbers == 5) {
      if ( $line =~ /^(\d+) (\d+) (\d+) (\d+) (\d+)$/ ) {
        my %numbers_mappings;
        foreach (@numbers) {
          $numbers_mappings { $_ } = 1;
          if ( $_ < 1 or $_ > 90 ) {
            $error .= " * \'$_\' - illegális intervallum! A számnak 1 és 90 közzé kell esnie!\n";
          }
        }
        if ( scalar @numbers != scalar keys %numbers_mappings ) { $error .= " * \'$line\' - nem lehetnek ismétlődő számok egy sorban!\n" }
      }
    }
    elsif (scalar @numbers == 6) {
      if ( $line =~ /^(\d+) (\d+) (\d+) (\d+) (\d+) (\d+)$/ ) {
        my %numbers_mappings;
        foreach (@numbers) {
          $numbers_mappings { $_ } = 1;
          if ( $_ < 1 or $_ > 45 ) {
            $error .= " * \'$_\' - illegális intervallum! A számnak 1 és 45 közzé kell esnie!\n";
          }
        }
        if ( scalar @numbers != scalar keys %numbers_mappings ) { $error .= " * \'$line\' - nem lehetnek ismétlődő számok egy sorban!\n" }
      }
    }
    elsif ( scalar @numbers == 7) {
      if ( $line =~ /^(\d+) (\d+) (\d+) (\d+) (\d+) (\d+) (\d+)$/ ) {
        my %numbers_mappings;
        foreach (@numbers) {
          $numbers_mappings { $_ } = 1;
          if ( $_ < 1 or $_ > 35 ) {
            $error .= " * \'$_\' - illegális intervallum! A számnak 1 és 35 közzé kell esnie!\n";
          }
        }
        if ( scalar @numbers != scalar keys %numbers_mappings ) { $error .= " * \'$line\' - nem lehetnek ismétlődő számok egy sorban!\n" }
      }
    }
  }
  return $error;
}

sub syntax_check_joker {
  my $line = shift;
  my @numbers;

  if ( $line =~ /\d{6}/) { @numbers = split //, $line } else {
    @numbers = split / /, $line
  }

  my $error = '';

  my $toomany = 0;
  my $not_enough = 0;
  my $not_number = 0;

  if (scalar @numbers > 6) { $toomany = 1 }
  if (scalar @numbers < 6) { $not_enough = 1}
  foreach (@numbers) {
    if ($_ =~ /\D+/) { $not_number = 1 }
  }

  SWITCH : {
    ( $toomany && $not_number ) && do { $error .= " * \'$line\' - túl sok elem / nem szám!\n"; last SWITCH };
    ( $not_enough && $not_number) && do { $error .= " * \'$line\' - túl kevés elem / nem szám!\n"; last SWITCH};
    ( $toomany ) && do { $error .= " * \'$line\' - túl sok szám!\n"; last SWITCH };
    ( $not_number ) && do { $error .= " * \'$line\' - nem szám!\n"; last SWITCH };
    ( $not_enough ) && do { $error .= " * \'$line\' - túl kevés szám!\n"; last SWITCH }
  }

  if ($error eq '') {
    foreach (@numbers) {
      if ( $_ < 0 or $_ > 9 ) {
        $error .= " * \'$_\' - illegális intervallum! A számnak 0 és 9 közzé kell esnie!\n";
      }
    }
  }
  return $error;
}

sub five_header {
  my $yearIn;
  my $weekNum;
  my $dateOfLot;
  my $fiveHitNo;
  my $fiveHitPay;
  my $fourHitNo;
  my $fourHitPay;
  my $threeHitNo;
  my $threeHitPay;
  my $twoHitNo;
  my $twoHitPay;
  my $report;
  my @winner;

  open ( my $otos_fh , "<", "otos.html") or die "Nem tudom megnyitni a fájlt: 'otos.html' $!";
  while (my $row = <$otos_fh>) {
    if ($row =~ /^\s+<\/tr><tr><td>(\d+)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td>/ ) {
      $yearIn = $1;
      $weekNum = $2;
      $dateOfLot = $3;
      $fiveHitNo = $4;
      $fiveHitPay = nmf($5);
      $fourHitNo = $6;
      $fourHitPay = nmf($7);
      $threeHitNo = $8;
      $threeHitPay = nmf($9);
      $twoHitNo = $10;
      $twoHitPay = nmf($11);

    if ($row =~ /<td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><\/tr>/) {
      push @winner, $1;
      push @winner, $2;
      push @winner, $3;
      push @winner, $4;
      push @winner, $5;
    }

    }
  }
  close $otos_fh;

  $report .= "\nÖtöslottó $yearIn $weekNum. heti sorsolása.\n";
  $report .= " Húzásdátum: $dateOfLot";
  $report .= " Nyerőszámok: " . "@winner" . "\n";
  $report .= " Ötös találatok száma: " . $fiveHitNo . " Nyeremény: " . $fiveHitPay . "\n";
  $report .= " Négyes találatok száma: " . $fourHitNo . " Nyeremény: " . $fourHitPay . "\n";
  $report .= " Hármas találatok száma: " . $threeHitNo . " Nyeremény: " . $threeHitPay . "\n";
  $report .= " Kettes találatok száma: " . $threeHitNo . " Nyeremény: " . $twoHitPay . "\n";

  return $report;
}

sub five {
  my $myNumbers = shift;

  my @winner;
  my @hit;
  my $report;

  open ( my $otos_fh , "<", "otos.html") or die "Nem tudom megnyitni a fájlt: 'otos.html' $!";
  while (my $row = <$otos_fh>) {
    if ($row =~ /^\s+<\/tr><tr><td>(\d+)<\/td><td>(\d+)<\/td><td>/) {
      if ( $row =~ /<td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><\/tr>/ ) {
        push @winner, $1;
        push @winner, $2;
        push @winner, $3;
        push @winner, $4;
        push @winner, $5;
      }
    }
  }
  close $otos_fh;

  foreach my $win (@winner) {
    foreach my $myNumber ( @$myNumbers ) {
      if ($win eq $myNumber) {
        push @hit, $myNumber
      }
    }
  }

  if (scalar @hit) { $report .= "  ---> ELTALÁLT SZÁMOK: " . "@hit" . "\n" } else { $report .= "  ---> NINCS TALÁLAT.\n" }
  return $report;
}

sub six_header {
  my $yearIn;
  my $weekNum;
  my $dateOfLot;
  my $sixHitNo;
  my $sixHitPay;
  my $fivep1HitNo;
  my $fivep1HitPay;
  my $fiveHitNo;
  my $fiveHitPay;
  my $fourHitNo;
  my $fourHitPay;
  my $threeHitNo;
  my $threeHitPay;
  my $report;
  my @winner;

  open ( my $hatos_fh , "<", "hatos.html") or die "Nem tudom megnyitni a fájlt: 'hatos.html' $!";
  while (my $row = <$hatos_fh>) {
    if ($row =~ /^\s+<\/tr><tr><td>(\d+)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td>/ ) {
      $yearIn = $1;
      $weekNum = $2;
      $dateOfLot = $3;
      $sixHitNo = $4;
      $sixHitPay = nmf($5);
      $fivep1HitNo = $6;
      $fivep1HitPay = $7;
      $fiveHitNo = $8;
      $fiveHitPay = nmf($9);
      $fourHitNo = $10;
      $fourHitPay = nmf($11);
      $threeHitNo = $12;
      $threeHitPay = nmf($13);

    if ($row =~ /<td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><\/tr>/) {
      push @winner, $1;
      push @winner, $2;
      push @winner, $3;
      push @winner, $4;
      push @winner, $5;
      push @winner, $6
    }

    }
  }
  close $hatos_fh;

  $report .= "\nHatoslottó $yearIn $weekNum. heti sorsolása.\n";
  $report .= " Húzásdátum: $dateOfLot";
  $report .= " Nyerőszámok: " . "@winner" . "\n";
  $report .= " Hatos találatok száma: " . $sixHitNo . " Nyeremény " . $sixHitPay . "\n";
  $report .= " Öt + 1 találatok száma: " . $fivep1HitNo . " Nyeremény: " . $fivep1HitPay . "\n";
  $report .= " Ötös találatok száma: " . $fiveHitNo . " Nyeremény: " . $fiveHitPay . "\n";
  $report .= " Négyes találatok száma: " . $fourHitNo . " Nyeremény: " . $fourHitPay . "\n";
  $report .= " Hármas találatok száma: " . $threeHitNo . " Nyeremény: " . $threeHitPay . "\n";

  return $report;
}

sub six {
  my $myNumbers = shift;
  my @winner;
  my @hit;
  my $report;

  open ( my $hatos_fh , "<", "hatos.html") or die "Nem tudom megnyitni a fájlt: 'hatos.html' $!";
  while (my $row = <$hatos_fh>) {
    if ($row =~ /^\s+<\/tr><tr><td>(\d+)<\/td><td>(\d+)<\/td><td>/) {
      if ( $row =~ /<td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><\/tr>/ ) {
        push @winner, $1;
        push @winner, $2;
        push @winner, $3;
        push @winner, $4;
        push @winner, $5;
        push @winner, $6;
      }
    }
  }
  close $hatos_fh;

  foreach my $win (@winner) {
    foreach my $myNumber ( @$myNumbers ) {
      if ($win eq $myNumber) {
        push @hit, $myNumber
      }
    }
  }

  if (scalar @hit) { $report .= "  ---> ELTALÁLT SZÁMOK: " . "@hit" . "\n" } else { $report .= "  ---> NINCS TALÁLAT.\n" }
  return $report;

}


sub seven_header {
  my $yearIn;
  my $weekNum;
  my $dateOfLot;
  my $sevenHitNo;
  my $sevenHitPay;
  my $sixHitNo;
  my $sixHitPay;
  my $fiveHitNo;
  my $fiveHitPay;
  my $fourHitNo;
  my $fourHitPay;
  my $report;
  my @machine_winner;
  my @hand_winner;

  open ( my $seven_fh , "<", "skandi.html") or die "Nem tudom megnyitni a fájlt: 'skandi.html' $!";
  while (my $row = <$seven_fh>) {
    if ($row =~ /^\s+<\/tr><tr><td>(\d+)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>/) {
      $yearIn = $1;
      $weekNum = $2;
      $dateOfLot = $3;
      $sevenHitNo = $4;
      $sevenHitPay = nmf($5);
      $sixHitNo = $6;
      $sixHitPay = nmf($7);
      $fiveHitNo = $8;
      $fiveHitPay = nmf($9);
      $fourHitNo = $10;
      $fourHitPay = nmf($11);
      if ($row =~ /td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><\/tr>/) {
        push @machine_winner, $1;
        push @machine_winner, $2;
        push @machine_winner, $3;
        push @machine_winner, $4;
        push @machine_winner, $5;
        push @machine_winner, $6;
        push @machine_winner, $7;
        push @hand_winner, $8;
        push @hand_winner, $9;
        push @hand_winner, $10;
        push @hand_winner, $11;
        push @hand_winner, $12;
        push @hand_winner, $13;
        push @hand_winner, $14;
      }
    }
  }
  close $seven_fh;

  $report .= "\nSkandináv lottó $yearIn $weekNum. heti sorsolása.\n";
  $report .= " Húzásdátum: $dateOfLot\n";
  $report .= " Nyerőszámok (gépi): " . "@machine_winner" . "\n";
  $report .= " Nyerőszámok (kézi): " . "@hand_winner" . "\n";
  $report .= " Telitalálatok száma: " . $sevenHitNo . " Nyeremény " . $sevenHitPay . "\n";
  $report .= " Hatos találatok száma: " . $sixHitNo . " Nyeremény " . $sixHitPay . "\n";
  $report .= " Ötös találatok száma: " . $fiveHitNo . " Nyeremény: " . $fiveHitPay . "\n";
  $report .= " Négyes találatok száma: " . $fourHitNo . " Nyeremény: " . $fourHitPay . "\n";

  return $report;

}

sub seven {
  my $myNumbers = shift;
  my @machine_winner;
  my @hand_winner;
  my @machine_hit;
  my @hand_hit;
  my $report;

  open ( my $seven_fh , "<", "skandi.html") or die "Nem tudom megnyitni a fájlt: 'skandi.html' $!";
  while (my $row = <$seven_fh>) {
        if ($row =~ /^\s+<\/tr><tr><td>(\d+)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>/) {
            if ($row =~ /td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><\/tr>/) {
              push @machine_winner, $1;
              push @machine_winner, $2;
              push @machine_winner, $3;
              push @machine_winner, $4;
              push @machine_winner, $5;
              push @machine_winner, $6;
              push @machine_winner, $7;
              push @hand_winner, $8;
              push @hand_winner, $9;
              push @hand_winner, $10;
              push @hand_winner, $11;
              push @hand_winner, $12;
              push @hand_winner, $13;
              push @hand_winner, $14;
            }
        }
  }
  close $seven_fh;

  foreach my $mwin (@machine_winner) {
    foreach my $myNumber (@$myNumbers) {
      if ( $mwin eq $myNumber) {
        push @machine_hit, $myNumber;
      }
    }
  }

  foreach my $hwin (@hand_winner) {
    foreach my $myNumber (@$myNumbers) {
        if ($hwin eq $myNumber) {
          push @hand_hit, $myNumber;
        }
    }
  }

  if (scalar @machine_hit) { $report .= "  ---> ELTALÁLT SZÁMOK (GÉPI): " . "@machine_hit" . "\n" } else { $report .= "  ---> NINCS TALÁLAT (GÉPI).\n" }
  if (scalar @hand_hit) { $report .= "  ---> ELTALÁLT SZÁMOK (KÉZI): " . "@hand_hit" . "\n" } else { $report .= "  ---> NINCS TALÁLAT (KÉZI).\n" }
  return $report;
}

sub joker_header {
  my $yearIn;
  my $weekNum;
  my $dateOfLot;
  my $sixHitNo;
  my $sixHitPay;
  my $fiveHitNo;
  my $fiveHitPay;
  my $fourHitNo;
  my $fourHitPay;
  my $threeHitNo;
  my $threeHitPay;
  my $twoHitNo;
  my $twoHitPay;
  my $report;
  my @winner;

  open ( my $joker_fh , "<", "joker.html") or die "Nem tudom megnyitni a fájlt: 'joker.html' $!";
  while (my $row = <$joker_fh>) {
    if ($row =~ /^\s+<\/tr><tr><td>(\d+)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td><td>(\d+)<\/td><td>(.+?)<\/td>/ ) {
      $yearIn = $1;
      $weekNum = $2;
      $dateOfLot = $3;
      $sixHitNo = $4;
      $sixHitPay = nmf($5);
      $fiveHitNo = $6;
      $fiveHitPay = nmf($7);
      $fourHitNo = $8;
      $fourHitPay = nmf($9);
      $threeHitNo = $10;
      $threeHitPay = nmf($11);
      $twoHitNo = $12;
      $twoHitPay = nmf($13);


      if ($row =~ /<td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><\/tr>/) {
        push @winner, $1;
        push @winner, $2;
        push @winner, $3;
        push @winner, $4;
        push @winner, $5;
        push @winner, $6
      }

    }
  }

  close $joker_fh;

  $report .= "\nJoker $yearIn $weekNum. heti sorsolása.\n";
  $report .= " Húzásdátum: $dateOfLot";
  $report .= " Nyerőszámok: " . "@winner" . "\n";
  $report .= " Telitalálatok száma: " . $sixHitNo . " Nyeremény " . $sixHitPay . "\n";
  $report .= " Ötös találatok száma: " . $fiveHitNo . " Nyeremény: " . $fiveHitPay . "\n";
  $report .= " Négyes találatok száma: " . $fourHitNo . " Nyeremény: " . $fourHitPay . "\n";
  $report .= " Hármas találatok száma: " . $threeHitNo . " Nyeremény: " . $threeHitPay . "\n";
  $report .= " Kettes találatok száma: " . $twoHitNo . " Nyeremény: " . $twoHitPay . "\n";

  return $report;
}

sub joker {
  my $myNumbers = shift;
  my @winner;
  my @hit;
  my $report;

  open ( my $joker_fh , "<", "joker.html") or die "Nem tudom megnyitni a fájlt: 'joker.html' $!";
  while (my $row = <$joker_fh>) {
    if ($row =~ /^\s+<\/tr><tr><td>(\d+)<\/td><td>(\d+)<\/td><td>/) {
      if ( $row =~ /<td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><\/tr>/ ) {
        push @winner, $1;
        push @winner, $2;
        push @winner, $3;
        push @winner, $4;
        push @winner, $5;
        push @winner, $6;
      }
    }
  }
  close $joker_fh;

  my $allowed = 'YES';
  do {
    my $myNumber = pop @$myNumbers;
    my $win = pop @winner;
    if ($myNumber eq $win) {
      unshift @hit, $myNumber;
    } else { $allowed = 'NO' }
  } until ( ( scalar @winner == 0 ) or ( $allowed eq 'NO' ) );

  if (scalar @hit) { $report .= "  ---> ELTALÁLT SZÁMOK: " . "@hit" . "\n" } else { $report .= "  ---> NINCS TALÁLAT.\n" }
  return $report;

}
