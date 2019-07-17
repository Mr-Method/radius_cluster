=head1 NAME

 billd plugin

 DESCRIBE: Odoo import accounts


 Arguments:
   FIELDS_INFO       - Show field info
   TYPE              - Synsc system type
   SYNCHRON_ODOO_FIELDS  - Odoo sync field
   DOMAIN_ID         - DOmain id
   SKIP_SERVICE      - Skip sync service
   SKIP_WRONG_MAIL
   SYNC_COMPANY      - Add company main account
   IMPORT_LIMIT      - Import limit count

   ODOO_CUSTOM=1
   PRODUCT_TYPES
   CATEGORY_IDS

  if($attr->{CATEGORY_IDS})

 Config:
   $conf{SYNCHRON_ODOO_FIELDS}='odoo_field:abills_field_id;';





1.	Интеграция с системой Odoo (OpenERP):
  - синхронизация данных при создании клиента (заполнение карточки клиента, изменение данных)
  - создание и/или синхронизация данных по инвойсам
  - синхронизация данных по клиентским платежам
  - формирование SOA по клиенту (отчет о всех инвойсах и платежах, связанных с данным клиентом)

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Abills::Base qw(show_hash load_pmodule);
use Abills::Filters qw(_utf8_encode);
use Synchron::Odoo;
use Frontier::Client;
use Tariffs;
use Users;
use Internet;
use Companies;

our (
  $argv,
  $DATE,
  $TIME,
  $debug,
  $Nas,
  $db,
  $Sessions,
  %conf,
  $Admin,
);

my $Users        = Users->new($db, $Admin, \%conf);
my $Companies    = Companies->new($db, $Admin, \%conf);
my $import_limit = $argv->{IMPORT_LIMIT} || 1000000000;
my $admin        = $Admin;
my $Tariffs      = Tariffs->new($db, \%conf, $admin);

if($argv->{ODOO_CUSTOM}) {
  odoo_custom();
}
elsif($argv->{FIELDS_INFO}) {
  fields_info();
}
else {
  sync_system()
}

#**********************************************************
=head2 fields_info();

=cut
#**********************************************************
sub fields_info {

  my $type = $argv->{TYPE} || q{odoo};
  my $fn = $type .'_field_info';
  &{ \&$fn }();

  return 1;
}


#**********************************************************
=head2 odoo_import();

=cut
#**********************************************************
sub sync_system {

  my $type = $argv->{TYPE} || q{odoo};
  my $fn = $type .'_import';
  &{ \&$fn }();

  return 1;
}


#**********************************************************
=head2 odoo_field_info();

=cut
#**********************************************************
sub odoo_field_info {

  odoo_import({ FIELDS_INFO => 1 });

  return 1;
}

#**********************************************************
=head2 odoo_custom($attr);

  Argumnets:
    $attr

  Results:

=cut
#**********************************************************
sub odoo_custom {

  if($debug > 1) {
    print "odoo_custom\n";
  }

  my Synchron::Odoo $Odoo = odoo_connect({ JSON => 1 });

  my $users_list_json  = $Odoo->read_partner_contracts({
    %$argv
  });

#  print "----------------------\n";
#  print "VERSION: $users_list_json->{version}\n";
#  print "\n----------------------\n";
#  #print "jsontext: ". $users_list_json->{jsontext};
#  print "\n----------------------\n";
#  print "is_success: ". $users_list_json->{is_success};
#  print "\n----------------------\n";
#  print "content: ". $users_list_json->{content};
#  print "\n----------------------\n";

  load_pmodule('JSON');
  my $json = JSON->new->allow_nonref;

  my $perl_scalar = $json->decode($users_list_json->{jsontext});
  #foreach my $country ( @{ $perl_scalar->{result} } ) {
  #  print $country->{id}."\n";
  #}

  company_import2($perl_scalar->{result});

  return 1;
}

#**********************************************************
=head2 odoo_connect($attr);

  Argumnets:
    $attr

  Results:

=cut
#**********************************************************
sub odoo_connect {
  my ($attr) = @_;

  my $url      = $conf{SYNCHRON_ODOO_URL} || 'https://demo.odoo.com:8069';
  my $dbname   = $conf{SYNCHRON_ODOO_DBNAME} || 'demo';
  my $username = $conf{SYNCHRON_ODOO_USERNAME} || 'admin';
  my $password = $conf{SYNCHRON_ODOO_PASSWORD} || 'admin';

  $url =~ s/\/$//;

  if($debug) {
    print "Odoo connect\n";
    if($debug > 2) {
      print "DOMAIN_ID: $admin->{DOMAIN_ID} URL: $url DB: $dbname USER: $username PASSWORD: $password\n";
    }
  }

  my $Odoo = Synchron::Odoo->new({
    LOGIN    => $username,
    PASSWORD => $password,
    URL      => $url,
    DBNAME   => $dbname,
    DEBUG    => ($debug > 4) ? $debug : 0,
    CONF     => \%conf,
    JSON     => ($attr->{JSON}) ? 1 : undef
  });

  if($Odoo->{errno}) {
    print "ERROR: Odoo $Odoo->{errno} $Odoo->{errstr}\n";
  }

  return $Odoo;
}

#**********************************************************
=head2 odoo_import();

  Arguments:
    $attr
  Results:

=cut
#**********************************************************
sub odoo_import {
  my ($attr)=@_;

  my Synchron::Odoo $Odoo = odoo_connect();

  my $sync_fields = q{};

  if($conf{SYNCHRON_ODOO_FIELDS}) {
    $conf{SYNCHRON_ODOO_FIELDS}=~s/\n//g;

    my @sync_fields_info = split(/;/, $conf{SYNCHRON_ODOO_FIELDS});
    my @sync_fields = ();
    foreach my $line (@sync_fields_info) {
      my($fld, undef)=split(/:/, $line);
      push @sync_fields, $fld;
    }
    $sync_fields = join(',', @sync_fields);
  }

  if($attr->{FIELDS_INFO}) {
    my $fields = $Odoo->fields_info();

    foreach my $key  ( sort keys %{ $fields } ) {
      print "$key : $fields->{$key}\n";
    }
  }
  else {
    my $users_list = $Odoo->user_list({
      FIELDS => $sync_fields
    });

    if($argv->{SYNC_COMPANY}) {
      company_import($users_list);
    }
    else {
      user_import($users_list);
    }

    #DEBUG:
    if(! $argv->{SKIP_SERVICE}) {
      my $service_list = $Odoo->contracts_list();

      if($argv->{SYNC_COMPANY}) {
        odoo_service_sync_company($service_list);
      }
      else {
        #Service sync
        odoo_service_sync($service_list);
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 user_import($users_list); - Sync users

=cut
#**********************************************************
sub user_import {
  my($users_list)=@_;

  my $count        = 0;
  my $update_count = 0;
  my $domain_id    = 0;

  if($argv->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID}=$argv->{DOMAIN_ID};
    $domain_id=$argv->{DOMAIN_ID};
  }

  if($debug > 3) {
    print "Sync fields\n";
    my $result_fields = $users_list->[0];
    print show_hash($result_fields, { DELIMITER => "\n" });
  }

  foreach my $user_info ( @$users_list ) {
    my $sync_field = 'LOGIN';
    print "Sync field: $sync_field Remote filed: ". (($user_info->{$sync_field}) ? $user_info->{$sync_field} : 'Not defined' )."\n" if ($debug > 1);

    $Users->{debug}=1 if($debug > 6);
    my $user_list = $Users->list({
      $sync_field  => $user_info->{$sync_field},
      REGISTRATION => '_SHOW',
      COLS_NAME    => '_SHOW'
    });

    if ($Users->{TOTAL}) {
      if($debug > 1) {
        print "====> $user_info->{LOGIN} exists UID: $user_list->[0]->{uid} REGISTRATION: $user_list->[0]->{registration}\n";
      }

      $argv->{UPDATE}=1;
      if($argv->{UPDATE}) {
        my $uid = $user_list->[0]->{uid};
        $Users->info($uid);
        $Users->pi({ UID => $uid });

        foreach my $key ( sort keys %$Users ) {
          if(defined($user_info->{$key})) {
            $user_info->{$key} //= q{};
            if(! defined($Users->{$key})) {
              next;
            }

            if($Users->{$key} ne $user_info->{$key}) {
              if(! $Users->{$key} && ! $user_info->{$key} ) {
                next;
              }

              Encode::_utf8_off($user_info->{$key});
              Encode::_utf8_off($Users->{$key});
              print "$key: $Users->{$key} -> $user_info->{$key}\n" if($debug > 2);
              $Users->change($uid, {
                %{ $user_info },
                UID => $uid
              });

              $Users->pi_change({
                %{ $user_info },
                UID => $uid
              });
              $update_count++;
            }
          }
        }

        #sync_internet({
        #  EXT_SYSTEM => $user_info,
        #  UID        => $uid
        #});

        if($debug > 10) {
          print "--------------------------------------------\n\n";
          show_hash($user_info);
          exit;
        }
      }

      next;
    }

    if($debug > 0) {
      print "ADD LOGIN $sync_field: $user_info->{$sync_field}\n";
    }

    if(! $user_info->{PASSWORD}) {
      $user_info->{PASSWORD} //= $user_info->{LOGIN}.'1234567890';
    }

    if ($argv->{SKIP_WRONG_MAIL} && $user_info->{EMAIL}) {
      if ($user_info->{EMAIL} !~ /(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
        delete $user_info->{EMAIL};
      }
    }

    my Users $User = $Users->add({
      %{ $user_info },
      CREATE_BILL => 1,
      DOMAIN_ID   => $domain_id
    });

    if(! $User->{errno}) {
      print "Registred UID: $User->{UID}\n";
      $user_info->{UID}=$User->{UID};
      $User->pi_add($user_info);
    }
    else {
      if($Users->{errno} == 11) {
        print "Error: $User->{errno} $User->{errstr} '$user_info->{EMAIL}'\n";
      }
      else {
        print "Error: $User->{errno} $User->{errstr}\n";
      }
    }

    $count++;
    if($count > $import_limit) {
      exit;
    }
  }

  if($debug > 1) {
    print "Count ADD: $count UPDATE: $update_count\n"
  }

  return 1;
}


##**********************************************************
#=head2 sync_internet($user_info);
#
#  Argumnets:
#    $attr
#      EXT_SYSTEM => $user_info,
#      UID        => $uid
#
#  Returns:
#
#  Examples:
#
#=cut
##**********************************************************
#sub sync_internet {
#  my ($attr)=@_;
#
#  my $user_info = $attr->{EXT_SYSTEM};
#  my $uid       = $attr->{UID};
#
#  my $internet_services = $Internet->list({
#    TP_ID     => '_SHOW',
#    CID       => '_SHOW',
#    IP        => '_SHOW',
#    UID       => $uid,
#    SHOW_COLS => 1
#  });
#
#  foreach my $i_info (@$internet_services) {
#    print "UID: $i_info->{UID} ID: $i_info->{ID} TP_ID: $i_info->{TP_ID} IP: $i_info->{IP}\n";
#
#    foreach my $param (keys %$i_info) {
#      print "$param: $i_info->{$param} <- ". (($user_info) ? $user_info->{$param} : q{})  ."\n";
#    }
#  }
#
#  return 1;
#}


#**********************************************************
=head2 _get_tp();


=cut
#**********************************************************
sub _get_tp {

  #$Tariffs = Tariffs->new($db, \%conf, $Admin);
  my %tps_list = ();

  my $list = $Tariffs->list({
    NAME      => '_SHOW',
    DOMAIN_ID => $admin->{DOMAIN_ID},
    COLS_NAME => 1
  });

  foreach my $line (@$list) {
    if($debug > 3) {
      print "'$line->{name}' $line->{tp_id} (DOMAIN: $admin->{DOMAIN_ID})\n";
    }
    $tps_list{$line->{name}}=$line->{tp_id}
  }

  return \%tps_list;
}


#**********************************************************
=head2 odoo_service_sync($service_list);

  Arguments:
    $service_list

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub odoo_service_sync {
  my ($service_list)=@_;

  my %login2uid = ();
  my $logins_list = $Users->list({
    LOGIN     => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 100000
  });

  foreach my $line (@$logins_list) {
    $login2uid{$line->{login}}=$line->{uid};
  }

  my $tp_ids = _get_tp();
  my $Internet = Internet->new($db, $Admin, \%conf);

  my $i = 0;
  foreach my $info (@$service_list) {
    $i++;
    print $i."- $info->{id}\n" if($debug > 1);
    my %user_tp = ();
    if($info->{partner_id} &&  ref $info->{partner_id} eq 'ARRAY' && $info->{partner_id}->[0] ) {
      print "LOGIN: " . ($info->{partner_id}->[0] || 'n/d')
        . " IP: $info->{ip_antenna} TP_ID: \n" if ($debug > 1);
    }
    else {
      next;
    }

    my $ip = (ref $info->{ip_antenna}  eq '') ? $info->{ip_antenna} : '0.0.0.0';
    my $cid = (ref $info->{mac_antenna}  eq '') ? $info->{mac_antenna} : '';
    my $login = $info->{partner_id}->[0];

    foreach my $tp_name  (@{ $info->{product_id} }) {
      if($tp_ids->{$tp_name}) {
        my $tp_id = $tp_ids->{$tp_name};
        $user_tp{$tp_id}++;
        print "  $tp_name ($tp_id)\n" if($debug>2);
      }
      else {
        print "  $tp_name ('n/d')\n" if($debug>2);
      }
    }

    my $service_count = scalar(keys %user_tp);

    my $internet_list = $Internet->list({
      LOGIN     => $login,
      TP_ID     => '_SHOW',
      ID        => '_SHOW',
      CID       => '_SHOW',
      GROUP_BY  => 'internet.id',
      COLS_NAME => 1
    });

    if($Internet->{TOTAL}) {
      foreach my $list ( @$internet_list ) {
        if($user_tp{$list->{tp_id}}) {
          print "LOGIN: $login TP: $list->{tp_id} !!!!!!!!!!!!!!!!!!!!! exist service\n" if($debug > 1);
          if ($user_tp{$list->{tp_id}} == 1) {
            delete $user_tp{$list->{tp_id}};
          }
          else {
            $user_tp{$list->{tp_id}}--;
          }
        }
        # Change tp on main system
        elsif($service_count == 1) {
          my @tps = keys %user_tp;
          my $new_tp = $tps[0] || 0;
          if($debug > 1) {
            print "CHANGE: $internet_list->[0]->{uid} -> $new_tp\n";
          }

          if($new_tp) {
            $Internet->add({
              UID   => $internet_list->[0]->{uid},
              TP_ID => $new_tp,
              IP    => $ip,
              CID   => $cid,
              CHECK_EXIST_TP => 1
            });

            if($Internet->{errno}) {
              print "ERROR: $Internet->{errno} $Internet->{errstr}\n";
            }
          }

#          print "$login // ". ($internet_list->[0]->{id} || q{-})
#            .", // ". ($internet_list->[0]->{uid} || q{--})
#            .", // ". ($ip || q{---}) ."\n";

          delete $user_tp{$list->{tp_id}};
        }

        $Internet->change({
          ID    => $internet_list->[0]->{id},
          UID   => $internet_list->[0]->{uid},
          CID   => $cid,
          #TP_ID => $new_tp,
          IP    => $ip
        });

      }
    }

    foreach my $tp_id ( keys %user_tp ) {
      if(! $login2uid{$login}) {
        print "Unknow UID for LOGIN: $login\n ";
        next;
      }
      #print "!!! $login // $user_tp{$tp_id} //\n";
      for (my $num=1; $num<=$user_tp{$tp_id} || 0; $num++) {
        if ($debug > 0) {
          print "ADD: " . ($login2uid{$login} || qq{NO UID LOGIN: $login }) . " -> " . ($tp_id || 'n/d') . "\n";
        }

        $Internet->add({
          UID   => $login2uid{$login},
          TP_ID => $tp_id,
          IP    => $ip,
          CID   => $cid,
          CHECK_EXIST_TP => 1
        });

        if($Internet->{errno}) {
          print "ERROR: [$Internet->{errno}] $Internet->{errstr}\n";
        }

        if ($user_tp{$tp_id} == 1) {
          #delete $user_tp{$tp_id};
        }
        else {
          $user_tp{$tp_id}--;
        }
      }
    }
  }

  return 1;
}


#**********************************************************
=head2 company_import($users_list); - Sync users

  Arguments:
    $users_list

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub company_import {
  my($users_list)=@_;

  my $count        = 0;
  my $update_count = 0;
  my $domain_id    = 0;

  if($argv->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID}=$argv->{DOMAIN_ID};
    $domain_id=$argv->{DOMAIN_ID};
  }

  if($debug > 3) {
    print "Sync fields\n";
    my $result_fields = $users_list->[0];
    print show_hash($result_fields, { DELIMITER => "\n" });
  }

  foreach my $user_info ( @$users_list ) {
    my $sync_field = 'LOGIN';
    print "Sync field: $sync_field Remote filed: ". (($user_info->{$sync_field}) ? $user_info->{$sync_field} : 'Not defined' )."\n" if ($debug > 1);

    my $abills_sync_field = $sync_field;
    if($sync_field eq 'LOGIN') {
      $abills_sync_field = '_ODOO';
      $user_info->{_ODOO} = $user_info->{$sync_field};
    }
    elsif($sync_field eq 'LOGIN') {
      $abills_sync_field = 'COMPANY_NAME';
      $user_info->{$abills_sync_field} = $user_info->{$sync_field};
    }

    $user_info->{NAME}=$user_info->{FIO};

    if($debug > 3) {
      print "=================================\n";
      print show_hash($user_info, { DELIMITER => "\n" });
    }

    $Companies->{debug}=1 if($debug > 6);
    my $user_list = $Companies->list({
      $abills_sync_field => $user_info->{$sync_field},
      REGISTRATION   => '_SHOW',
      COLS_NAME      => '_SHOW',
      SKIP_DEL_CHECK => 1
    });

    if ($Companies->{TOTAL}) {
      if($debug > 1) {
        print "====> $user_info->{LOGIN} exists COMPANY_ID: $user_list->[0]->{id} REGISTRATION: $user_list->[0]->{registration}\n";
      }

#      $argv->{UPDATE}=1;
      if($argv->{UPDATE}) {
        my $company_id = $user_list->[0]->{id};
        $Companies->info($company_id);

        foreach my $key ( sort keys %$Companies ) {
          if(defined($user_info->{$key})) {
            $user_info->{$key} //= q{};
            if(! defined($Companies->{$key})) {
              next;
            }

            if($Companies->{$key} ne $user_info->{$key}) {
              if(! $Companies->{$key} && ! $user_info->{$key} ) {
                next;
              }

              Encode::_utf8_off($user_info->{$key});
              Encode::_utf8_off($Companies->{$key});
              print "$key: $Companies->{$key} -> $user_info->{$key}\n" if($debug > 2);

              $Companies->change({
                %{ $user_info },
                ID => $company_id
              });
              $update_count++;
            }
          }
        }

        #sync_internet({
        #  EXT_SYSTEM => $user_info,
        #  UID        => $uid
        #});

        if($debug > 10) {
          print "--------------------------------------------\n\n";
          show_hash($user_info);
          exit;
        }
      }

      next;
    }

    if($debug > 0) {
      print "ADD LOGIN $sync_field: $user_info->{$sync_field}\n";
    }

    if(! $user_info->{PASSWORD}) {
      $user_info->{PASSWORD} //= $user_info->{LOGIN}.'1234567890';
    }

    if ($argv->{SKIP_WRONG_MAIL} && $user_info->{EMAIL}) {
      if ($user_info->{EMAIL} !~ /(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
        delete $user_info->{EMAIL};
      }
    }

    my Companies $Company = $Companies->add({
      %{ $user_info },
      CREATE_BILL => 1,
      DOMAIN_ID   => $domain_id
    });

    if(! $Company->{errno}) {
      print "REGISTRED COMPANY_ID: $Company->{ID}\n";
      $user_info->{ID}=$Company->{ID};
    }
    else {
      if($Company->{errno} == 11) {
        print "ERROR: $Company->{errno} $Company->{errstr} '$user_info->{EMAIL}'\n";
      }
      else {
        print "ERROR: $Company->{errno} $Company->{errstr}\n";
      }
    }

    $count++;
    if($count > $import_limit) {
      return 1;
    }
  }

  if($debug > 1) {
    print "COUNT ADD: $count UPDATE: $update_count\n"
  }

  return 1;
}

#**********************************************************
=head2 company_import2($users_list); - Sync users

  Arguments:
    $users_list

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub company_import2 {
  my($users_list)=@_;

  my $count        = 0;
  my $update_count = 0;
  my $domain_id    = 0;

  if($argv->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID}=$argv->{DOMAIN_ID};
    $domain_id=$argv->{DOMAIN_ID};
  }

  if($debug > 2) {
    print "IMPORT COUNT: ". ($#{$users_list}+1) ."\n";
  }

  if($debug > 3) {
    print "Sync fields\n";
    my $result_fields = $users_list->[0];
    print show_hash($result_fields, { DELIMITER => "\n" });
  }

  foreach my $user_info ( @$users_list ) {

    if($domain_id) {
      $user_info->{DOMAIN_ID}=$domain_id;
    }

    my $sync_field = 'COMPANY_NAME';
    print "Sync field: $sync_field Remote filed: ". (($user_info->{id}) ? $user_info->{id} : 'Not defined' )."\n" if ($debug > 1);

    my $abills_sync_field = $sync_field;
    $abills_sync_field = 'COMPANY_NAME';
    $user_info->{$abills_sync_field} = $user_info->{$sync_field};
    $user_info->{COMPANY_NAME}=$user_info->{name} || $user_info->{FIO} || q{};
    $user_info->{NAME}=$user_info->{name} || $user_info->{FIO} || q{};

    if($debug > 3) {
      print "=================================\n";
      print show_hash($user_info, { DELIMITER => "\n" });
    }

    if(! $user_info->{$sync_field}) {
      print "ERROR: Key field not defined: ". ($abills_sync_field || q{empty_key}) . " => ". ($user_info->{$sync_field} || q{empty}) . " ID: $user_info->{id}\n";
      next;
    }

    $Companies->{debug}=1 if($debug > 6);

    my $user_list = $Companies->list({
      $abills_sync_field => $user_info->{$sync_field},
      #PHONE          => $user_info->{phone},
      REGISTRATION   => '_SHOW',
      COLS_NAME      => '_SHOW',
      SKIP_DOMAIN    => '_SHOW',
      DOMAIN_ID      => undef,
      SKIP_DEL_CHECK => 1
    });

    if ($Companies->{TOTAL}) {
      if($debug > 1) {
        print "====> $user_info->{id} exists COMPANY_ID: $user_list->[0]->{id} REGISTRATION: $user_list->[0]->{registration}\n";
      }

      #      $argv->{UPDATE}=1;
      my $company_id = $user_list->[0]->{id};
      if($argv->{UPDATE}) {
        $Companies->info($company_id);

        foreach my $key ( sort keys %$Companies ) {
          if(defined($user_info->{$key})) {
            $user_info->{$key} //= q{};
            if(! defined($Companies->{$key})) {
              next;
            }

            if($Companies->{$key} ne $user_info->{$key}) {
              if(! $Companies->{$key} && ! $user_info->{$key} ) {
                next;
              }

              Encode::_utf8_off($user_info->{$key});
              Encode::_utf8_off($Companies->{$key});
              print "$key: $Companies->{$key} -> $user_info->{$key}\n" if($debug > 2);

              $Companies->change({
                %{ $user_info },
                ID => $company_id
              });
              $update_count++;
            }
          }
        }

        #sync_internet({
        #  EXT_SYSTEM => $user_info,
        #  UID        => $uid
        #});

        if($debug > 10) {
          show_hash($user_info);
          exit;
        }
      }

      $user_info->{COMPANY_ID}=$company_id;
      add_user($user_info);
      next;
    }

    if($debug > 0) {
      print "ADD COMPANY: $sync_field: ". ($user_info->{$sync_field} || 'n/d') ." ID: $user_info->{id}\n";
    }

    if(! $user_info->{PASSWORD}) {
      $user_info->{PASSWORD} //= $user_info->{id}.'1234567890';
    }

    if ($argv->{SKIP_WRONG_MAIL} && $user_info->{EMAIL}) {
      if ($user_info->{EMAIL} !~ /(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
        delete $user_info->{EMAIL};
      }
    }

    if($debug > 7) {
      $Companies->{debug} = 1;
    }

    my Companies $Company = $Companies->add({
      %{$user_info},
      #NAME        => $user_info->{id},
      PHONE       => $user_info->{phone},
      CREATE_BILL => 1,
      DOMAIN_ID   => $domain_id,
      ID          => undef
    });

    if(! $Company->{errno}) {
      print "REGISTRED COMPANY_ID: $Company->{ID}\n";
      $user_info->{ID}=$Company->{ID};
    }
    else {
      if($Company->{errno} == 11) {
        print "ERROR: $Company->{errno} $Company->{errstr} '$user_info->{EMAIL}'\n";
      }
      elsif($Company->{errno} == 8) {
        print "ERROR: Not defined company_name $Company->{errno} $Company->{errstr}\n";
      }
      else {
        print "ERROR: COMAPNY_ADD $Company->{errno} $Company->{errstr}\n";
      }
    }

    $count++;
    if($count > $import_limit) {
      return 1;
    }
  }

  if($debug > 1) {
    print "COUNT ADD: $count UPDATE: $update_count\n"
  }

  return 1;
}


#**********************************************************
=head2 add_user($service_list);

=cut
#**********************************************************
sub add_user {
  my($services_info)=@_;

  foreach my $service_info ( @{ $services_info->{contracts} } ) {
    if($debug > 1) {
      print "\nLOGIN: " . $service_info->{contract_id} . " \n"
        . "TP_NAME: $service_info->{contract_lines}->[0]->{product_name} \n"
        . "COMPANY_ID: $services_info->{id} \n"
      ;
    }

    if($debug > 6) {
       $Users->{debug}=1;
    }

    my $u_list = $Users->list({ LOGIN => $service_info->{contract_id}, COLS_NAME => 1 });

    my %users_params = (
      LOGIN      => $service_info->{contract_id},
      PASSWORD   => $service_info->{router_password},
      COMPANY_ID => $services_info->{COMPANY_ID},
    );

    if($argv->{DOMAIN_ID}) {
      $users_params{DOMAIN_ID}=$argv->{DOMAIN_ID};
      $service_info->{DOMAIN_ID}=$argv->{DOMAIN_ID};
    }

    if(! $Users->{TOTAL}) {
      $Users->add({
        %users_params,
        CREATE_BILL=> 1
      });

      $service_info->{UID}=$Users->{UID};
      add_internet($service_info);
    }
    else {
      $Users->change($u_list->[0]->{uid}, {
        UID        => $u_list->[0]->{uid},
        %users_params
      });

      $service_info->{UID}=$u_list->[0]->{uid};
      add_internet($service_info);
    }
  }

  return 1;
}


#**********************************************************
=head2 odoo_service_sync($service_info);

  Arguments:
    $service_info

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub add_internet {
  my ($service_info)=@_;

  my $Internet = Internet->new($db, $Admin, \%conf);

  if($debug > 6) {
    $Internet->{debug} = 1;
  }

  $Internet->list({ UID => $service_info->{UID} });

  my $tp_name = $service_info->{contract_lines}->[0]->{product_name};
  my $tp_ids = _get_tp();
  my $ip    = (ref $service_info->{ip_antenna}  eq '') ? $service_info->{ip_antenna} : '0.0.0.0';
  my $cid   = (ref $service_info->{mac_antenna}  eq '') ? $service_info->{mac_antenna} : '';

  Encode::_utf8_off($tp_name);
  if(! $tp_ids->{"$tp_name"}) {
    if($debug > 6) {
      $Tariffs->{debug}=1;
    }

    print ">>>>>>>>>>>>>>>>>>>>>>>>> '$tp_name' ". ($tp_ids->{$tp_name} || q{}) ."\n\n";

    $Tariffs->add({
      #ID        => 0,
      NAME      => $tp_name,
      #MONTH_FEE => $add_values{4}{MONTH_FEE},
      #USER_CREDIT_LIMIT => $add_values{4}{USER_CREDIT_LIMIT},
      MODULE    => 'Internet',
      DOMAIN_ID => $service_info->{DOMAIN_ID}
    });
    $tp_ids->{$tp_name} = $Tariffs->{TP_ID};

    if($debug > 4) {
      print "ADD TP: '$tp_name' DOMAIN_ID: ". ($service_info->{DOMAIN_ID} || q{}) ." ID: $Tariffs->{TP_ID}\n";

      foreach my $key ( sort keys %$tp_ids ) {
        print "-- '$key' '$tp_ids->{$key}'\n";
      }
    }

    exit;
  }

  if(! $Internet->{TOTAL}) {
    $Internet->add({
      UID   => $service_info->{UID},
      TP_ID => $tp_ids->{$tp_name} || 0,
      IP    => $ip,
      CID   => $cid,
      PASSWORD  => $service_info->{router_password},
      LOGIN  => $service_info->{router_user},
      CHECK_EXIST_TP => 1
    });
  }
  else {
    $Internet->change({
      UID   => $service_info->{UID},
      TP_ID => $tp_ids->{$tp_name} || 0,
      IP    => $ip,
      CID   => $cid,
      PASSWORD  => $service_info->{router_password},
      LOGIN  => $service_info->{router_user},
      CHECK_EXIST_TP => 1
    });
  }

  if($Internet->{errno}) {
    print "ERROR: $Internet->{errno} $Internet->{errstr} UID: $service_info->{UID}\n";
  }

  return 1;
}


#**********************************************************
=head2 odoo_service_sync($service_list);

  Arguments:
    $service_list

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub odoo_service_sync_company {
  my ($service_list)=@_;

  my %login2uid = ();
  my $domain_id = 0;
  if($argv->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID}=$argv->{DOMAIN_ID};
    $domain_id=$argv->{DOMAIN_ID};
  }

  my $logins_list = $Users->list({
    LOGIN      => '_SHOW',
    COMPANY_ID => '_SHOW',
    CONTRACT_ID=> '_SHOW',
    COLS_NAME  => 1,
    PAGE_ROWS  => 1000000
  });

  foreach my $line (@$logins_list) {
    $login2uid{$line->{login}}=$line->{uid};
  }

  my %odoo2company = ();

  my $company_list = $Companies->list({
    _ODOO     => '_SHOW',
    COMPANY_ID=> '_SHOW',
    DOMAIN_ID => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 100000,
    SKIP_DEL_CHECK => 1
  });

  foreach my $line (@$company_list) {
    $odoo2company{$line->{_odoo}}=$line->{id};
  }

  my $tp_ids = _get_tp();
  my $Internet = Internet->new($db, $Admin, \%conf);

  my $i = 0;
  foreach my $info (@$service_list) {
    $i++;
    print $i."- $info->{id}\n" if($debug > 1);

    my %user_tp = ();
    if($info->{partner_id} &&  ref $info->{partner_id} eq 'ARRAY' && $info->{partner_id}->[0] ) {
      if ($debug > 1) {
        print "LOGIN: " . ($info->{partner_id}->[0] || 'n/d')
          . " IP: $info->{ip_antenna} TP_ID: \n";
      }
    }
    else {
      next;
    }

    my $ip    = (ref $info->{ip_antenna}  eq '') ? $info->{ip_antenna} : '0.0.0.0';
    my $cid   = (ref $info->{mac_antenna}  eq '') ? $info->{mac_antenna} : '';
    my $login = $info->{partner_id}->[0];
    my $odoo_id = $info->{partner_id}->[0];
    # ABillS TP
    my $product_id = $info->{product_id}->[0];

    if(! $product_id) {
      print "-----------------------------------------\n";
      print $info->{product_id};
      print "///////\n";
      print @{ $info->{product_id} };
      print "-----------------------------------------\n";
      next;
    }

    my $uid   = $login2uid{$product_id};

    foreach my $tp_name  (@{ $info->{product_id} }) {
      if($tp_ids->{$tp_name}) {
        my $tp_id = $tp_ids->{$tp_name};
        $user_tp{$tp_id}++;
        print "  $tp_name ($tp_id)\n" if($debug>2);
      }
      else {
        print "  $tp_name ('n/d')\n" if($debug>2);
      }
    }

    if($debug > 1) {
      show_hash($info, { DELIMITER => "\n" });
    }

    if(! $uid) {
      if($debug > 3) {
        print "ADD LOGIN/CONTRACT: $info->{product_id}->[0] / \n";
      }

      if(! $odoo2company{$odoo_id}) {
        print "ERROR: No company: '_odoo' ODOO_ID: $odoo_id // $info->{id}\n";
        next;
      }

      if(! $login2uid{$info->{product_id}->[0]} ) {
        my Users $User = $Users->add({
          LOGIN       => $info->{product_id}->[0],
          COMPANY_ID  => $odoo2company{$odoo_id},
          CREATE_BILL => 1,
          DOMAIN_ID   => $domain_id
        });

        if (!$User->{errno}) {
          print "REGISTRED UID: $User->{UID}\n";
          $User->pi_add({
            CONTARCT_ID => $info->{product_id}->[0],
            UID         => $User->{UID}
          });
        }
        else {
          if ($Users->{errno} == 11) {
            print "Error: $User->{errno} $User->{errstr} '->{EMAIL}'\n";
          }
          else {
            print "Error: $User->{errno} $User->{errstr}\n";
          }
        }
      }

      exit;
    }


    print "!!!!!!!\n";
    next;
    my $service_count = scalar(keys %user_tp);

    my $internet_list = $Internet->list({
      LOGIN     => $login,
      TP_ID     => '_SHOW',
      ID        => '_SHOW',
      CID       => '_SHOW',
      GROUP_BY  => 'internet.id',
      COLS_NAME => 1
    });

    if($Internet->{TOTAL}) {
      foreach my $list ( @$internet_list ) {
        if($user_tp{$list->{tp_id}}) {
          print "LOGIN: $login TP: $list->{tp_id} !!!!!!!!!!!!!!!!!!!!! exist service\n" if($debug > 1);
          if ($user_tp{$list->{tp_id}} == 1) {
            delete $user_tp{$list->{tp_id}};
          }
          else {
            $user_tp{$list->{tp_id}}--;
          }
        }
        # Change tp on main system
        elsif($service_count == 1) {
          my @tps = keys %user_tp;
          my $new_tp = $tps[0] || 0;
          if($debug > 1) {
            print "CHANGE: $internet_list->[0]->{uid} -> $new_tp\n";
          }

          if($new_tp) {
            $Internet->add({
              UID   => $internet_list->[0]->{uid},
              TP_ID => $new_tp,
              IP    => $ip,
              CID   => $cid,
              CHECK_EXIST_TP => 1
            });

            if($Internet->{errno}) {
              print "ERROR: $Internet->{errno} $Internet->{errstr}\n";
            }
          }

          #          print "$login // ". ($internet_list->[0]->{id} || q{-})
          #            .", // ". ($internet_list->[0]->{uid} || q{--})
          #            .", // ". ($ip || q{---}) ."\n";

          delete $user_tp{$list->{tp_id}};
        }

        $Internet->change({
          ID    => $internet_list->[0]->{id},
          UID   => $internet_list->[0]->{uid},
          CID   => $cid,
          #TP_ID => $new_tp,
          IP    => $ip
        });

      }
    }

    foreach my $tp_id ( keys %user_tp ) {
      if(! $login2uid{$login}) {
        print "Unknow UID for LOGIN: $login\n ";
        next;
      }
      #print "!!! $login // $user_tp{$tp_id} //\n";
      for (my $num=1; $num<=$user_tp{$tp_id} || 0; $num++) {
        if ($debug > 0) {
          print "ADD: " . ($login2uid{$login} || qq{NO UID LOGIN: $login }) . " -> " . ($tp_id || 'n/d') . "\n";
        }

        $Internet->add({
          UID   => $login2uid{$login},
          TP_ID => $tp_id,
          IP    => $ip,
          CID   => $cid,
          CHECK_EXIST_TP => 1
        });

        if($Internet->{errno}) {
          print "ERROR: [$Internet->{errno}] $Internet->{errstr}\n";
        }

        if ($user_tp{$tp_id} == 1) {
          #delete $user_tp{$tp_id};
        }
        else {
          $user_tp{$tp_id}--;
        }
      }
    }
  }

  return 1;
}



1;