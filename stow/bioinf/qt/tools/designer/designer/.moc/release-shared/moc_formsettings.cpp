/****************************************************************************
** FormSettingsBase meta object code from reading C++ file 'formsettings.h'
**
** Created: Sat Dec 12 03:14:32 2009
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.8   edited Feb 2 14:59 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "../../formsettings.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.8. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *FormSettingsBase::className() const
{
    return "FormSettingsBase";
}

QMetaObject *FormSettingsBase::metaObj = 0;
static QMetaObjectCleanUp cleanUp_FormSettingsBase( "FormSettingsBase", &FormSettingsBase::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString FormSettingsBase::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "FormSettingsBase", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString FormSettingsBase::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "FormSettingsBase", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* FormSettingsBase::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QDialog::staticMetaObject();
    static const QUMethod slot_0 = {"okClicked", 0, 0 };
    static const QUMethod slot_1 = {"languageChange", 0, 0 };
    static const QMetaData slot_tbl[] = {
	{ "okClicked()", &slot_0, QMetaData::Public },
	{ "languageChange()", &slot_1, QMetaData::Protected }
    };
    metaObj = QMetaObject::new_metaobject(
	"FormSettingsBase", parentObject,
	slot_tbl, 2,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_FormSettingsBase.setMetaObject( metaObj );
    return metaObj;
}

void* FormSettingsBase::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "FormSettingsBase" ) )
	return this;
    return QDialog::qt_cast( clname );
}

bool FormSettingsBase::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: okClicked(); break;
    case 1: languageChange(); break;
    default:
	return QDialog::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool FormSettingsBase::qt_emit( int _id, QUObject* _o )
{
    return QDialog::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool FormSettingsBase::qt_property( int id, int f, QVariant* v)
{
    return QDialog::qt_property( id, f, v);
}

bool FormSettingsBase::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
