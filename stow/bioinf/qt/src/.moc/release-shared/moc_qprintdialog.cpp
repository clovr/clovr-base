/****************************************************************************
** QPrintDialog meta object code from reading C++ file 'qprintdialog.h'
**
** Created: Sat Dec 12 03:13:42 2009
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.8   edited Feb 2 14:59 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "../../dialogs/qprintdialog.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.8. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *QPrintDialog::className() const
{
    return "QPrintDialog";
}

QMetaObject *QPrintDialog::metaObj = 0;
static QMetaObjectCleanUp cleanUp_QPrintDialog( "QPrintDialog", &QPrintDialog::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString QPrintDialog::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QPrintDialog", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString QPrintDialog::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QPrintDialog", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* QPrintDialog::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QDialog::staticMetaObject();
    static const QUMethod slot_0 = {"browseClicked", 0, 0 };
    static const QUMethod slot_1 = {"okClicked", 0, 0 };
    static const QUParameter param_slot_2[] = {
	{ 0, &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod slot_2 = {"printerOrFileSelected", 1, param_slot_2 };
    static const QUParameter param_slot_3[] = {
	{ 0, &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod slot_3 = {"landscapeSelected", 1, param_slot_3 };
    static const QUParameter param_slot_4[] = {
	{ 0, &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod slot_4 = {"paperSizeSelected", 1, param_slot_4 };
    static const QUParameter param_slot_5[] = {
	{ 0, &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod slot_5 = {"orientSelected", 1, param_slot_5 };
    static const QUParameter param_slot_6[] = {
	{ 0, &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod slot_6 = {"pageOrderSelected", 1, param_slot_6 };
    static const QUParameter param_slot_7[] = {
	{ 0, &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod slot_7 = {"colorModeSelected", 1, param_slot_7 };
    static const QUParameter param_slot_8[] = {
	{ 0, &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod slot_8 = {"setNumCopies", 1, param_slot_8 };
    static const QUParameter param_slot_9[] = {
	{ 0, &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod slot_9 = {"printRangeSelected", 1, param_slot_9 };
    static const QUParameter param_slot_10[] = {
	{ 0, &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod slot_10 = {"setFirstPage", 1, param_slot_10 };
    static const QUParameter param_slot_11[] = {
	{ 0, &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod slot_11 = {"setLastPage", 1, param_slot_11 };
    static const QUParameter param_slot_12[] = {
	{ "text", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_12 = {"fileNameEditChanged", 1, param_slot_12 };
    static const QMetaData slot_tbl[] = {
	{ "browseClicked()", &slot_0, QMetaData::Private },
	{ "okClicked()", &slot_1, QMetaData::Private },
	{ "printerOrFileSelected(int)", &slot_2, QMetaData::Private },
	{ "landscapeSelected(int)", &slot_3, QMetaData::Private },
	{ "paperSizeSelected(int)", &slot_4, QMetaData::Private },
	{ "orientSelected(int)", &slot_5, QMetaData::Private },
	{ "pageOrderSelected(int)", &slot_6, QMetaData::Private },
	{ "colorModeSelected(int)", &slot_7, QMetaData::Private },
	{ "setNumCopies(int)", &slot_8, QMetaData::Private },
	{ "printRangeSelected(int)", &slot_9, QMetaData::Private },
	{ "setFirstPage(int)", &slot_10, QMetaData::Private },
	{ "setLastPage(int)", &slot_11, QMetaData::Private },
	{ "fileNameEditChanged(const QString&)", &slot_12, QMetaData::Private }
    };
    metaObj = QMetaObject::new_metaobject(
	"QPrintDialog", parentObject,
	slot_tbl, 13,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_QPrintDialog.setMetaObject( metaObj );
    return metaObj;
}

void* QPrintDialog::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "QPrintDialog" ) )
	return this;
    return QDialog::qt_cast( clname );
}

bool QPrintDialog::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: browseClicked(); break;
    case 1: okClicked(); break;
    case 2: printerOrFileSelected((int)static_QUType_int.get(_o+1)); break;
    case 3: landscapeSelected((int)static_QUType_int.get(_o+1)); break;
    case 4: paperSizeSelected((int)static_QUType_int.get(_o+1)); break;
    case 5: orientSelected((int)static_QUType_int.get(_o+1)); break;
    case 6: pageOrderSelected((int)static_QUType_int.get(_o+1)); break;
    case 7: colorModeSelected((int)static_QUType_int.get(_o+1)); break;
    case 8: setNumCopies((int)static_QUType_int.get(_o+1)); break;
    case 9: printRangeSelected((int)static_QUType_int.get(_o+1)); break;
    case 10: setFirstPage((int)static_QUType_int.get(_o+1)); break;
    case 11: setLastPage((int)static_QUType_int.get(_o+1)); break;
    case 12: fileNameEditChanged((const QString&)static_QUType_QString.get(_o+1)); break;
    default:
	return QDialog::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool QPrintDialog::qt_emit( int _id, QUObject* _o )
{
    return QDialog::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool QPrintDialog::qt_property( int id, int f, QVariant* v)
{
    return QDialog::qt_property( id, f, v);
}

bool QPrintDialog::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
