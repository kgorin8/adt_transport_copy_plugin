class ZCL_ADT_TOC definition
  public
  inheriting from CL_ADT_DISC_RES_APP_BASE
  final
  create public .

public section.
protected section.

  methods GET_APPLICATION_TITLE
    redefinition .
  methods REGISTER_RESOURCES
    redefinition .
  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_ADT_TOC IMPLEMENTATION.


  METHOD GET_APPLICATION_TITLE.
    result = 'ADT Transport of Copies'(001).
  ENDMETHOD.


  method register_resources.

    data collection type ref to if_adt_discovery_collection.

    collection = registry->register_discoverable_resource( exporting
       url      = '/adt_toc/toc'
       handler_class   = 'CL_ADT_REST_RESOURCE'
       description     = 'ADT Transport of Copies'(001)
       category_scheme = 'http://github.com/kgorin8/adt_transport_copy_plugin'
       category_term   = 'toc' ).

    collection->register_disc_res_w_template( exporting
      relation      = 'http://github.com/kgorin8/adt_transport_copy_plugin/toc/create'
      template      = '/adt_toc/toc/{transport}/{action}'
      description   = 'ADT Transport of Copies'(001)
      handler_class = 'ZCL_ADT_TOC_RES' ).

  endmethod.
ENDCLASS.
