"""Shims on top of ogrext for GDAL versions > 2"""

import logging
import os

from fiona.ogrext2 cimport *
from fiona._err cimport exc_wrap_pointer
from fiona._err import cpl_errs, CPLE_BaseError, FionaNullPointerError
from fiona.errors import DriverError


log = logging.getLogger(__name__)


cdef bint is_field_null(void *feature, int n):
    if not OGR_F_IsFieldSet(feature, n):
        return True
    else:
        return False


cdef void set_field_null(void *feature, int n):
    pass


cdef void gdal_flush_cache(void *cogr_ds):
    with cpl_errs:
        GDALFlushCache(cogr_ds)


cdef void* gdal_open_vector(const char* path_c, int mode, drivers, options) except NULL:
    cdef void* cogr_ds = NULL
    cdef char **drvs = NULL
    cdef char **open_opts = NULL

    flags = GDAL_OF_VECTOR | GDAL_OF_VERBOSE_ERROR
    if mode == 1:
        flags |= GDAL_OF_UPDATE
    else:
        flags |= GDAL_OF_READONLY

    if drivers:
        for name in drivers:
            name_b = name.encode()
            name_c = name_b
            drv = GDALGetDriverByName(name_c)
            if drv != NULL:
                drvs = CSLAddString(drvs, name_c)

    for k, v in options.items():

        if v is None:
            continue

        k = k.upper().encode('utf-8')
        if isinstance(v, bool):
            v = ('ON' if v else 'OFF').encode('utf-8')
        else:
            v = str(v).encode('utf-8')
        log.debug("Set option %r: %r", k, v)
        open_opts = CSLAddNameValue(open_opts, <const char *>k, <const char *>v)

    open_opts = CSLAddNameValue(open_opts, "VALIDATE_OPEN_OPTIONS", "NO")

    try:
        cogr_ds = exc_wrap_pointer(GDALOpenEx(
            path_c, flags, <const char *const *>drvs, open_opts, NULL)
        )
        return cogr_ds
    except FionaNullPointerError:
        raise DriverError("Failed to open dataset (mode={}): {}".format(mode, path_c.decode("utf-8")))
    except CPLE_BaseError as exc:
        raise DriverError(str(exc))
    finally:
        CSLDestroy(drvs)
        CSLDestroy(open_opts)


cdef void* gdal_create(void* cogr_driver, const char *path_c, options) except NULL:
    cdef char **creation_opts = NULL

    for k, v in options.items():
        k = k.upper().encode('utf-8')
        if isinstance(v, bool):
            v = ('ON' if v else 'OFF').encode('utf-8')
        else:
            v = str(v).encode('utf-8')
        log.debug("Set option %r: %r", k, v)
        creation_opts = CSLAddNameValue(creation_opts, <const char *>k, <const char *>v)

    try:
        return exc_wrap_pointer(GDALCreate(cogr_driver, path_c, 0, 0, 0, GDT_Unknown, creation_opts))
    except FionaNullPointerError:
        raise DriverError("Failed to create dataset: {}".format(path_c.decode("utf-8")))
    except CPLE_BaseError as exc:
        raise DriverError(str(exc))
    finally:
        CSLDestroy(creation_opts)


cdef bint check_capability_transaction(void *cogr_ds):
    return GDALDatasetTestCapability(cogr_ds, ODsCTransactions)


cdef OGRErr gdal_start_transaction(void* cogr_ds, int force):
    return GDALDatasetStartTransaction(cogr_ds, force)


cdef OGRErr gdal_commit_transaction(void* cogr_ds):
    return GDALDatasetCommitTransaction(cogr_ds)


cdef OGRErr gdal_rollback_transaction(void* cogr_ds):
    return GDALDatasetRollbackTransaction(cogr_ds)


cdef OGRFieldSubType get_field_subtype(void *fielddefn):
    return OGR_Fld_GetSubType(fielddefn)


cdef void set_field_subtype(void *fielddefn, OGRFieldSubType subtype):
    OGR_Fld_SetSubType(fielddefn, subtype)


cdef bint check_capability_create_layer(void *cogr_ds):
    return GDALDatasetTestCapability(cogr_ds, ODsCCreateLayer)


cdef void *get_linear_geometry(void *geom):
    return OGR_G_GetLinearGeometry(geom, 0.0, NULL)

cdef const char* osr_get_name(OGRSpatialReferenceH hSrs):
    return ''

cdef void osr_set_traditional_axis_mapping_strategy(OGRSpatialReferenceH hSrs):
    OSRFixup(hSrs)


cdef void set_proj_search_path(object path):
    os.environ["PROJ_LIB"] = path


cdef void get_proj_version(int* major, int* minor, int* patch):
    cdef int val = -1
    major[0] = val
    minor[0] = val
    patch[0] = val


cdef void set_field_datetime(void *cogr_feature, int iField, int nYear, int nMonth, int nDay, int nHour, int nMinute, float fSecond, int nTZFlag):
    OGR_F_SetFieldDateTimeEx(cogr_feature, iField, nYear, nMonth, nDay, nHour, nMinute, fSecond, nTZFlag)


cdef int get_field_as_datetime(void *cogr_feature, int iField, int* nYear, int* nMonth, int* nDay, int* nHour, int* nMinute, float* fSecond, int* nTZFlag):
    return OGR_F_GetFieldAsDateTimeEx(cogr_feature, iField, nYear, nMonth, nDay, nHour, nMinute, fSecond, nTZFlag)
