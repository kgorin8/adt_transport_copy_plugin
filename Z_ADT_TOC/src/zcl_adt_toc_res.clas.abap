class ZCL_ADT_TOC_RES definition
  public
  inheriting from CL_ADT_REST_RESOURCE
  final
  create public .

public section.

  methods POST
    redefinition .
protected section.
private section.

  constants CS_TEXT_DESCRIPTION type AS4TEXT value ' : Generated test transport' ##NO_TEXT.
  constants CS_DEFAULT_TARGET type TR_TARGET value 'TARGET' ##NO_TEXT.

  methods GET_DEFAULT_TRANSPORT_TARGET
    returning
      value(R_DEFAULT_TRANSPORT_TARGET) type TR_TARGET .
  methods GET_TRANSPORT_REQUEST
    importing
      !REQUEST type ref to IF_ADT_REST_REQUEST
    returning
      value(R_RESULT) type TRKORR .
  methods GET_SHOULD_BE_RELEASED
    importing
      !REQUEST type ref to IF_ADT_REST_REQUEST
    returning
      value(R_RESULT) type ABAP_BOOL .
  methods CREATE_TRANSPORT_OF_COPIES
    importing
      !I_TRANS_REQUEST type TRKORR
      !I_SHOULD_BE_RELEASED type ABAP_BOOL
    raising
      CX_ADT_CTS_CREATE_ERROR
      CX_ADT_CTS_INSERT_ERROR
      CX_CTS_REST_API_EXCEPTION .
  methods CHECK_AUTHORITY
    importing
      !RELEASE type ABAP_BOOL
    returning
      value(SUCCESS) type ABAP_BOOL .
  methods CREATE_EMPTY_REQUEST
    importing
      !I_REQUEST_TEXT type AS4TEXT
    returning
      value(NEW_TRANSPORT_REQUEST) type TRKORR
    raising
      CX_ADT_CTS_CREATE_ERROR .
  methods COPY_OBJECTS
    importing
      !I_SOURCE_REQUEST type TRKORR
      !I_TARGET_REQUEST type TRKORR
    raising
      CX_ADT_CTS_INSERT_ERROR .
  methods RELEASE_REQUEST
    importing
      !I_TRANSPORT_REQUEST type TRKORR
    raising
      CX_CTS_REST_API_EXCEPTION .
  methods GET_TRANS_REQUEST_TEXT
    importing
      !I_TRANSPORT_REQUEST type TRKORR
    returning
      value(R_TEXT) type AS4TEXT .
ENDCLASS.



CLASS ZCL_ADT_TOC_RES IMPLEMENTATION.


method check_authority.

  success = abap_true.

  authority-check object 'S_TRANSPRT'
           id 'TTYPE' field 'TRAN'
           id 'ACTVT' field '01'.
  if sy-subrc <> 0.
    success = abap_false.
  endif.

  if release = abap_true.

    authority-check object 'S_TRANSPRT'
           id 'TTYPE' field 'TRAN'
           id 'ACTVT' field '43'.
    if sy-subrc <> 0.
      success = abap_false.
    endif.

  endif.

endmethod.                    "check_authority


method copy_objects.
  data: tasks type trwbo_request_headers.
  field-symbols: <task> type trwbo_request_header.

  call function 'TR_READ_REQUEST_WITH_TASKS'
    exporting
      iv_trkorr          = i_source_request
    importing
      et_request_headers = tasks
    exceptions
      invalid_input      = 1
      others             = 2.

  loop at tasks assigning <task>.
    call function 'TR_COPY_COMM'
      exporting
        wi_dialog                = abap_false
        wi_trkorr_from           = <task>-trkorr
        wi_trkorr_to             = i_target_request
        wi_without_documentation = abap_false
      exceptions
        db_access_error          = 1
        trkorr_from_not_exist    = 2
        trkorr_to_is_repair      = 3
        trkorr_to_locked         = 4
        trkorr_to_not_exist      = 5
        trkorr_to_released       = 6
        user_not_owner           = 7
        no_authorization         = 8
        wrong_client             = 9
        wrong_category           = 10
        object_not_patchable     = 11
        others                   = 12.
    if sy-subrc <> 0.
      raise exception type cx_adt_cts_insert_error.
    endif.
  endloop.
endmethod.                    "copy_objects


method create_empty_request.
  data: request_header type trwbo_request_header,
        exp            type ref to cx_root.

  cl_adt_cts_management=>create_empty_request(
    exporting
      iv_type           = 'T'
      iv_text           = i_request_text
      iv_target         = cs_default_target
    importing
      es_request_header = request_header ).

  new_transport_request = request_header-trkorr.

endmethod.                    "create_empty_request


method create_transport_of_copies.
  data: request_text          type as4text,
        new_transport_request type trkorr.

*    request_text = me->get_trans_request_text( i_trans_request ).
  concatenate i_trans_request cs_text_description into request_text.
  condense request_text.

  new_transport_request = me->create_empty_request( request_text ).
  me->copy_objects( i_source_request = i_trans_request
                    i_target_request = new_transport_request ).
  if i_should_be_released = abap_true.
    me->release_request( new_transport_request ).
  endif.
endmethod.                    "create_transport_of_copies


method get_default_transport_target.

  call function 'TR_GET_TRANSPORT_TARGET'
    exporting
      iv_use_default             = abap_true
    importing
      ev_target                  = r_default_transport_target
    exceptions
      wrong_call                 = 1
      invalid_input              = 2
      cts_initialization_failure = 3
      others                     = 4.

endmethod.                    "get_default_transport_target


method get_should_be_released.

  data action type string.

  try.
      request->get_uri_attribute( exporting
        name      = 'action'
        mandatory = abap_true importing
      value     = action ).
    catch cx_adt_rest.
  endtry.

  case action.
    when 'release'.
      r_result = abap_true.
    when 'create'.
      r_result = abap_false.
  endcase.

endmethod.                    "get_should_be_released


method get_transport_request.
  try.
      request->get_uri_attribute( exporting
        name      = 'transport'
        mandatory = abap_true importing
      value     = r_result ).
    catch cx_adt_rest.
  endtry.
endmethod.                    "get_transport_request


method get_trans_request_text.
  data: l_e07t     type e07t.

  call function 'TR_READ_COMM'
    exporting
      wi_trkorr        = i_transport_request
      wi_dialog        = abap_false
      wi_sel_e07t      = abap_true
    importing
      we_e07t          = l_e07t
    exceptions
      not_exist_e070   = 1
      no_authorization = 2
      others           = 3.
  if sy-subrc = 0.
    r_text = l_e07t-as4text.
  endif.
endmethod.                    "get_trans_request_text


method post.
  data: trans_request      type trkorr,
        should_be_released type abap_bool,
        authorised         type abap_bool.

  trans_request = me->get_transport_request( request ).
  should_be_released = me->get_should_be_released( request ).

  authorised = me->check_authority( should_be_released ).

  if ( authorised = abap_false ).
    response->set_status( status = cl_rest_status_code=>gc_client_error_unauthorized ).
    return.
  endif.

  if trans_request is initial.
    response->set_status( status = cl_rest_status_code=>gc_client_error_bad_request ).
    return.
  endif.

  try.
      me->create_transport_of_copies( i_trans_request      = trans_request
                                      i_should_be_released = should_be_released ).
      response->set_status( status = cl_rest_status_code=>gc_success_ok ).
    catch cx_static_check.
      response->set_status( status = cl_rest_status_code=>gc_server_error_internal ).
  endtry.
endmethod.                    "post


method release_request.
  data: cts_api type ref to if_cts_rest_api,
        exp     type ref to cx_root.

  cts_api = cl_cts_rest_api_factory=>create_instance( ).

  try.
      cts_api->release( iv_ignore_locks = abap_true
                        iv_ignore_objects_check = abap_true
                        iv_trkorr = i_transport_request ).
    catch cx_cts_rest_api_exception into exp.
      raise exception type cx_cts_rest_api_exception.
  endtry.

endmethod.                    "release_request
ENDCLASS.
