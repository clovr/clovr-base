/****************************************************************************
** SettingsDialogBase meta object code from reading C++ file 'settingsdialog.h'
**
** Created: Sat Dec 12 03:14:53 2009
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.8   edited Feb 2 14:59 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "../../settingsdialog.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.8. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *SettingsDialogBase::className() const
{
    return "SettingsDialogBase";
}

QMetaObject *SettingsDialogBase::metaObj = 0;
static QMetaObjectCleanUp cleanUp_SettingsDialogBase( "SettingsDialogBase", &SettingsDialogBase::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString SettingsDialogBase::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "SettingsDialogBase", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString SettingsDialogBase::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "SettingsDialogBase", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* SettingsDialogBase::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QDialog::staticMetaObject();
    static const QUMethod slot_0 = {"selectColor", 0, 0 };
    static const QUMethod slot_1 = {"browseWebApp", 0, 0 };
    static const QUMethod slot_2 = {"browsePDFApplication", 0, 0 };
    static const QUMethod slot_3 = {"browseHomepage", 0, 0 };
    static const QUMethod slot_4 = {"languageChange", 0, 0 };
    static const QMetaData slot_tbl[] = {
	{ "selectColor()", &slot_0, QMetaData::Public },
	{ "browseWebApp()", &slot_1, QMetaData::Public },
	{ "browsePDFApplication()", &slot_2, QMetaData::Public },
	{ "browseHomepage()", &slot_3, QMetaData::Public },
	{ "languageChange()", &slot_4, QMetaData::Protected }
    };
    metaObj = QMetaObject::new_metaobject(
	"SettingsDialogBase", parentObject,
	slot_tbl, 5,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_SettingsDialogBase.setMetaObject( metaObj );
    return metaObj;
}

void* SettingsDialogBase::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "SettingsDialogBase" ) )
	return this;
    return QDialog::qt_cast( clname );
}

bool SettingsDialogBase::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: selectColor(); break;
    case 1: browseWebApp(); break;
    case 2: browsePDFApplication(); break;
    case 3: browseHomepage(); break;
    case 4: languageChange(); break;
    default:
	return QDialog::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool SettingsDialogBase::qt_emit( int _id, QUObject* _o )
{
    return QDialog::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool SettingsDialogBase::qt_property( int id, int f, QVariant* v)
{
    return QDialog::qt_property( id, f, v);
}

bool SettingsDialogBase::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
