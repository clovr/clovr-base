/****************************************************************************
** DatabaseConnectionEditorBase meta object code from reading C++ file 'dbconnectioneditor.h'
**
** Created: Sat Dec 12 03:14:40 2009
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.8   edited Feb 2 14:59 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "../../dbconnectioneditor.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.8. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *DatabaseConnectionEditorBase::className() const
{
    return "DatabaseConnectionEditorBase";
}

QMetaObject *DatabaseConnectionEditorBase::metaObj = 0;
static QMetaObjectCleanUp cleanUp_DatabaseConnectionEditorBase( "DatabaseConnectionEditorBase", &DatabaseConnectionEditorBase::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString DatabaseConnectionEditorBase::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "DatabaseConnectionEditorBase", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString DatabaseConnectionEditorBase::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "DatabaseConnectionEditorBase", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* DatabaseConnectionEditorBase::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QDialog::staticMetaObject();
    static const QUMethod slot_0 = {"languageChange", 0, 0 };
    static const QUMethod slot_1 = {"init", 0, 0 };
    static const QUMethod slot_2 = {"destroy", 0, 0 };
    static const QMetaData slot_tbl[] = {
	{ "languageChange()", &slot_0, QMetaData::Protected },
	{ "init()", &slot_1, QMetaData::Protected },
	{ "destroy()", &slot_2, QMetaData::Protected }
    };
    metaObj = QMetaObject::new_metaobject(
	"DatabaseConnectionEditorBase", parentObject,
	slot_tbl, 3,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_DatabaseConnectionEditorBase.setMetaObject( metaObj );
    return metaObj;
}

void* DatabaseConnectionEditorBase::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "DatabaseConnectionEditorBase" ) )
	return this;
    return QDialog::qt_cast( clname );
}

bool DatabaseConnectionEditorBase::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: languageChange(); break;
    case 1: init(); break;
    case 2: destroy(); break;
    default:
	return QDialog::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool DatabaseConnectionEditorBase::qt_emit( int _id, QUObject* _o )
{
    return QDialog::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool DatabaseConnectionEditorBase::qt_property( int id, int f, QVariant* v)
{
    return QDialog::qt_property( id, f, v);
}

bool DatabaseConnectionEditorBase::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
