/****************************************************************************
** QToolTipGroup meta object code from reading C++ file 'qtooltip.h'
**
** Created: Sat Dec 12 03:13:32 2009
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.8   edited Feb 2 14:59 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "../../widgets/qtooltip.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.8. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#include <qvariant.h>
const char *QToolTipGroup::className() const
{
    return "QToolTipGroup";
}

QMetaObject *QToolTipGroup::metaObj = 0;
static QMetaObjectCleanUp cleanUp_QToolTipGroup( "QToolTipGroup", &QToolTipGroup::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString QToolTipGroup::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QToolTipGroup", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString QToolTipGroup::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QToolTipGroup", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* QToolTipGroup::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QObject::staticMetaObject();
    static const QUParameter param_slot_0[] = {
	{ 0, &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_0 = {"setDelay", 1, param_slot_0 };
    static const QUParameter param_slot_1[] = {
	{ 0, &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_1 = {"setEnabled", 1, param_slot_1 };
    static const QMetaData slot_tbl[] = {
	{ "setDelay(bool)", &slot_0, QMetaData::Public },
	{ "setEnabled(bool)", &slot_1, QMetaData::Public }
    };
    static const QUParameter param_signal_0[] = {
	{ 0, &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod signal_0 = {"showTip", 1, param_signal_0 };
    static const QUMethod signal_1 = {"removeTip", 0, 0 };
    static const QMetaData signal_tbl[] = {
	{ "showTip(const QString&)", &signal_0, QMetaData::Public },
	{ "removeTip()", &signal_1, QMetaData::Public }
    };
#ifndef QT_NO_PROPERTIES
    static const QMetaProperty props_tbl[2] = {
 	{ "bool","delay", 0x12000103, &QToolTipGroup::metaObj, 0, -1 },
	{ "bool","enabled", 0x12000103, &QToolTipGroup::metaObj, 0, -1 }
    };
#endif // QT_NO_PROPERTIES
    metaObj = QMetaObject::new_metaobject(
	"QToolTipGroup", parentObject,
	slot_tbl, 2,
	signal_tbl, 2,
#ifndef QT_NO_PROPERTIES
	props_tbl, 2,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_QToolTipGroup.setMetaObject( metaObj );
    return metaObj;
}

void* QToolTipGroup::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "QToolTipGroup" ) )
	return this;
    return QObject::qt_cast( clname );
}

// SIGNAL showTip
void QToolTipGroup::showTip( const QString& t0 )
{
    activate_signal( staticMetaObject()->signalOffset() + 0, t0 );
}

// SIGNAL removeTip
void QToolTipGroup::removeTip()
{
    activate_signal( staticMetaObject()->signalOffset() + 1 );
}

bool QToolTipGroup::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: setDelay((bool)static_QUType_bool.get(_o+1)); break;
    case 1: setEnabled((bool)static_QUType_bool.get(_o+1)); break;
    default:
	return QObject::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool QToolTipGroup::qt_emit( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->signalOffset() ) {
    case 0: showTip((const QString&)static_QUType_QString.get(_o+1)); break;
    case 1: removeTip(); break;
    default:
	return QObject::qt_emit(_id,_o);
    }
    return TRUE;
}
#ifndef QT_NO_PROPERTIES

bool QToolTipGroup::qt_property( int id, int f, QVariant* v)
{
    switch ( id - staticMetaObject()->propertyOffset() ) {
    case 0: switch( f ) {
	case 0: setDelay(v->asBool()); break;
	case 1: *v = QVariant( this->delay(), 0 ); break;
	case 3: case 4: case 5: break;
	default: return FALSE;
    } break;
    case 1: switch( f ) {
	case 0: setEnabled(v->asBool()); break;
	case 1: *v = QVariant( this->enabled(), 0 ); break;
	case 3: case 4: case 5: break;
	default: return FALSE;
    } break;
    default:
	return QObject::qt_property( id, f, v );
    }
    return TRUE;
}

bool QToolTipGroup::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
