*&---------------------------------------------------------------------*
*& Report ZRPS_BAL_TEST1
*&---------------------------------------------------------------------*
report zlog_demo1.

start-of-selection.

start-of-selection.
  data(ref_log) = new zcl_log( ).
  ref_log->set_object( 'ZRPS' ).
  ref_log->set_subobject( '1CREAR' ).
  ref_log->set_iddoc( 'ID-5' ).
  ref_log->search_or_create( ).
  ref_log->get_light( ).
  ref_log->add_msg( msgid = '/ASU/GENERAL' msgty = ref_log->c-msgty-success msgno = '019' ).
  ref_log->add_msg( msgid = '/ASU/GENERAL' msgty = ref_log->c-msgty-error msgno = '013' msgv1 = 'IDDOCUMENTO' ).
  ref_log->add_msg( msgid = '/ASU/GENERAL' msgty = ref_log->c-msgty-warning msgno = '003' ).
  ref_log->add_msg( msgid = '/ASU/GENERAL' msgty = ref_log->c-msgty-abort msgno = '003' ).
  ref_log->save( ).
  ref_log->display( ).
