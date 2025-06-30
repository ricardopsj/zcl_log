class ZCL_LOG definition
  public
  create public .

public section.

  data LOG_HANDLE type BALLOGHNDL .
  data S_LOG type BAL_S_LOG read-only .
  data LT_REPLACE_MESSAGE type BAL_T_RPLV .
  data LT_REPLACE_CONTEXT type BAL_T_RPLC .
  constants:
    begin of c
                 , begin of probclass
                   , very_important   type balprobcl value '1' " Very Important
                   , important        type balprobcl value '2' " Important
                   , medium           type balprobcl value '3' " Medium
                   , additional_info  type balprobcl value '4' " Additional Information
                   , other            type balprobcl value ''  " Other
                   , end of probclass
                 , begin of msgty
                   , success      type msgty value 'S' " Mensaje en imagen siguiente
                   , information  type msgty value 'I' " Información
                   , abort        type msgty value 'A' " Cancelación
                   , error        type msgty value 'E' " Error
                   , warning      type msgty value 'W' " Advertencia
                 , end of msgty
                 , end of c .
  data LT_LOG_HEADER type BALHDR_T .
  data LS_STATS type BAL_S_SCNT .

  methods ADD_MSG
    importing
      !MSGID type CLIKE
      !MSGNO type CLIKE
      !MSGTY type CLIKE
      !MSGV1 type CLIKE optional
      !MSGV2 type CLIKE optional
      !MSGV3 type CLIKE optional
      !MSGV4 type CLIKE optional
      !PROBCLASS type BALPROBCL optional .
  methods ADD_STD
    importing
      !PROBCLASS type BALPROBCL optional .
  methods CONSTRUCTOR .
  methods CREATE .
  methods DISPLAY
    importing
      !SHOW_ALL type ABAP_BOOL default ABAP_TRUE .
  methods GET_LIGHT
    returning
      value(LIGHT) type ICON_D .
  methods GET_STATS
    returning
      value(LIGHT) type ICON_D .
  methods LOAD
    returning
      value(LOADED) type ABAP_BOOL .
  methods OK
    returning
      value(OK) type ABAP_BOOL .
  methods SAVE .
  methods SAVE_PREPARE .
  methods SEARCH
    returning
      value(FOUND) type ABAP_BOOL .
  methods SEARCH_OR_CREATE .
  methods SET_IDDOC
    importing
      !IDDOC type CLIKE .
  methods SET_OBJECT
    importing
      !OBJECT type BAL_S_LOG-OBJECT .
  methods SET_SUBOBJECT
    importing
      !SUBOBJECT type BAL_S_LOG-SUBOBJECT .
  methods REFRESH .
  protected section.
  private section.
ENDCLASS.



CLASS ZCL_LOG IMPLEMENTATION.


  method add_msg.
    data: ls_msg type bal_s_msg.

    ls_msg-msgty     = msgty.
    ls_msg-msgid     = msgid.
    ls_msg-msgno     = msgno.
    ls_msg-msgv1     = zcl_ce=>output_string( msgv1 ).
    ls_msg-msgv2     = zcl_ce=>output_string( msgv2 ).
    ls_msg-msgv3     = zcl_ce=>output_string( msgv3 ).
    ls_msg-msgv4     = zcl_ce=>output_string( msgv4 ).
    if probclass is not supplied or probclass is initial.
      case msgty.
        when c-msgty-abort or c-msgty-error.
          ls_msg-probclass = c-probclass-very_important.
        when c-msgty-warning.
          ls_msg-probclass = c-probclass-medium.
        when c-msgty-information.
          ls_msg-probclass = c-probclass-additional_info.
        when c-msgty-success.
          ls_msg-probclass = c-probclass-important.
      endcase.
    endif.
    call function 'BAL_LOG_MSG_ADD'
      exporting
        i_log_handle  = log_handle
        i_s_msg       = ls_msg
      exceptions
        log_not_found = 1
        others        = 2.
    if sy-subrc <> 0.
      message id sy-msgid type sy-msgty number sy-msgno
              with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.


  endmethod.


  method add_std.
    add_msg( msgid = sy-msgid
             msgno = sy-msgno
             msgty = sy-msgty
             msgv1 = sy-msgv1
             msgv2 = sy-msgv2
             msgv3 = sy-msgv3
             msgv4 = sy-msgv4 ).
  endmethod.


  method constructor.
    field-symbols: <g>     type any.
    perform load in program saplsbal.             " for unicode-systems
    assign ('(SAPLSBAL)G') to <g>.
*    get reference of <g> into ref_s_gdat.
*    get reference of <g> into ref_s_gdat.
  endmethod.


  method create.
    call function 'BAL_LOG_CREATE'
      exporting
        i_s_log      = s_log
      importing
        e_log_handle = log_handle
      exceptions
        others       = 1.
    if sy-subrc <> 0.
      message id sy-msgid type sy-msgty number sy-msgno
              with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.
  endmethod.


  method display.
    data:
      l_s_display_profile type bal_s_prof.

* get a prepared profile
    call function 'BAL_DSP_PROFILE_SINGLE_LOG_GET'
      importing
        e_s_display_profile = l_s_display_profile
      exceptions
        others              = 1.
    if sy-subrc <> 0.
      message id sy-msgid type sy-msgty number sy-msgno
               with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.

* use grid for display if wanted
    l_s_display_profile-use_grid = abap_true.

* set report to allow saving of variants
    l_s_display_profile-disvariant-report = sy-repid.
* when you use also other ALV lists in your report,
* please specify a handle to distinguish between the display
* variants of these different lists, e.g:
    l_s_display_profile-disvariant-handle = 'LOG'.

* call display function module
* We do not specify any filter (like I_S_LOG_FILTER, ...,
* I_T_MSG_HANDLE) since we want to display all logs available
    call function 'BAL_DSP_LOG_DISPLAY'
      exporting
        i_s_display_profile = l_s_display_profile
      exceptions
        others              = 1.
    if sy-subrc <> 0.
      message id sy-msgid type sy-msgty number sy-msgno
               with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.
  endmethod.


  method get_light.
    get_stats( ).
    if ls_stats-msg_cnt_a ne 0.
      light = icon_breakpoint.
    elseif ls_stats-msg_cnt_e ne 0.
      light = icon_led_red.
    elseif ls_stats-msg_cnt_w ne 0.
      light = icon_led_yellow.
    elseif ls_stats-msg_cnt_i ne 0 or ls_stats-msg_cnt_s ne 0.
      light = icon_led_green.
    else.
      light = icon_businav_proc_exist.
      light = icon_dummy.
    endif.
  endmethod.


  method get_stats.
    clear: ls_stats.
    if log_handle is not initial.
      call function 'BAL_LOG_HDR_READ'
        exporting
          i_log_handle = log_handle
*         I_LANGU      = SY-LANGU
        importing
          e_s_log      = s_log
*         E_EXISTS_ON_DB                 =
*         E_CREATED_IN_CLIENT            =
*         E_SAVED_IN_CLIENT              =
*         E_IS_MODIFIED                  =
*         E_LOGNUMBER  =
          e_statistics = ls_stats
*         E_TXT_OBJECT =
*         E_TXT_SUBOBJECT                =
*         E_TXT_ALTCODE                  =
*         E_TXT_ALMODE =
*         E_TXT_ALSTATE                  =
*         E_TXT_PROBCLASS                =
*         E_TXT_DEL_BEFORE               =
*         E_WARNING_TEXT_NOT_FOUND       =
*     EXCEPTIONS
*         LOG_NOT_FOUND                  = 1
*         OTHERS       = 2
        .
    endif.
  endmethod.


  method load.
    if lt_log_header is not initial.
      call function 'BAL_DB_LOAD'
        exporting
          i_t_log_header = lt_log_header
        exceptions
          others         = 0.
      read table lt_log_header with key subobject = s_log-subobject reference into data(ref_log_header).
      if sy-subrc eq 0.
        log_handle = ref_log_header->log_handle.
      endif.
    endif.
    loaded = boolc( log_handle is not initial ).
  endmethod.


  method ok.
    get_stats( ).
    ok = boolc( ls_stats-msg_cnt_a eq 0 and ls_stats-msg_cnt_e eq 0 ).
  endmethod.


  method refresh.
    call function 'BAL_LOG_REFRESH'
      exporting
        i_log_handle  = log_handle
      exceptions
        log_not_found = 1
        others        = 2.
    if sy-subrc <> 0.
      message id sy-msgid type sy-msgty number sy-msgno with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.
    search_or_create( ).
    get_stats( ).
  endmethod.


  method save.
    save_prepare( ).
    call function 'BAL_DB_SAVE'
      exporting
        i_save_all = 'X'
      exceptions
        others     = 1.
    if sy-subrc <> 0.
      message id sy-msgid type sy-msgty number sy-msgno
              with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.
  endmethod.


  method save_prepare.
    call function 'BAL_DB_SAVE_PREPARE'
      exporting
        i_replace_in_all_logs         = 'X'
        i_t_replace_message_variables = lt_replace_message
        i_t_replace_context_fields    = lt_replace_context
      exceptions
        log_not_found                 = 0
        others                        = 1.
    if sy-subrc <> 0.
      message id sy-msgid type sy-msgty number sy-msgno
              with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.
  endmethod.


  method search.
    data: ls_filter     type bal_s_lfil.
    append value #( sign = 'I' option = 'EQ' low = s_log-object high = space ) to ls_filter-object.
    append value #( sign = 'I' option = 'EQ' low = s_log-subobject high = space ) to ls_filter-subobject.
    append value #( sign = 'I' option = 'EQ' low = s_log-extnumber high = space ) to ls_filter-extnumber.
    call function 'BAL_DB_SEARCH'
      exporting
        i_s_log_filter = ls_filter
      importing
        e_t_log_header = lt_log_header
      exceptions
        others         = 0.
    found = boolc( lt_log_header is not initial ).
  endmethod.


  method search_or_create.
    if search( ).
      load( ).
    else.
      create( ).
    endif.
  endmethod.


  method set_iddoc.
    s_log-extnumber = iddoc.
  endmethod.


  method set_object.
    s_log-object = object.
  endmethod.


  method set_subobject.
    s_log-subobject = subobject.
  endmethod.
ENDCLASS.
