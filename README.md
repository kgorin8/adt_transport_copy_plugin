**ADT Transport of Copies** plugin allows you to quickly create SAP transports from Eclipse

1. Install ABAP part using abapgit
2. Change CS_DEFAULT_TARGET in ZCL_ADT_TOC_RES class atributes to your desired QA system (this you fill in if you create toc in SE01)
3. Go so SICF and activate /sap/bc/adt/ service.
4. Point your Eclipse to https://raw.githubusercontent.com/kgorin8/adt_transport_copy_plugin/master/adt_transport_copy_site/site.xml
5. Open ADT workbench -> Transport Organizer. Right click on some transport and go to ADT Transport of Copies
6. Some debug info is output in console. If you don't see console open it from views.

Q. I'm getting 500 error from server.

A. Something bad happens during creation of transport. You will have to debug this yourself. However the most common reason is listed in step 2.

> This was largely done thanks to prior work from https://github.com/ceedee666/adt_transport_utils_plugin However I had to completely rewrite the code both on plugin and ABAP parts so I don't recognise this as a derivative work (as in Oracle vs Android action API names don't count). Also original plugin is no longer supported and I was unable to make it work due to messed up endpoints.
