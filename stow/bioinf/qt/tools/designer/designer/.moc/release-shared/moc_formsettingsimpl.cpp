/****************************************************************************
** FormSettings meta object code from reading C++ file 'formsettingsimpl.h'
**
** Created: Sat Dec 12 03:14:13 2009
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.8   edited Feb 2 14:59 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "../../formsettingsimpl.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.8. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *FormSettings::className() const
{
    return "FormSettings";
}

QMetaObject *FormSettings::metaObj = 0;
static QMetaObjectCleanUp cleanUp_FormSettings( "FormSettings", &FormSettings::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString FormSettings::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "FormSettings", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString FormSettings::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "FormSettings", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* FormSettings::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = FormSettingsBase::staticMetaObject();
    static const QUMethod slot_0 = {"okClicked", 0, 0 };
    static const QMetaData slot_tbl[] = {
	{ "okClicked()", &slot_0, QMetaData::Protected }
    };
    metaObj = QMetaObject::new_metaobject(
	"FormSettings", parentObject,
	slot_tbl, 1,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_FormSettings.setMetaObject( metaObj );
    return metaObj;
}

void* FormSettings::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "FormSettings" ) )
	return this;
    return FormSettingsBase::qt_cast( clname );
}

bool FormSettings::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: okClicked(); break;
    default:
	return FormSettingsBase::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool FormSettings::qt_emit( int _id, QUObject* _o )
{
    return FormSettingsBase::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool FormSettings::qt_property( int id, int f, QVariant* v)
{
    return FormSettingsBase::qt_property( id, f, v);
}

bool FormSettings::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
