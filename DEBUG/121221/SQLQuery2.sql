/*
@sesiune	6856ED4011C90	varchar
@parXML	<row aplicatie="PV" tip="PV" casamarcat="1" data="12/20/2012" inXML="0" UID="56E1C674-B8FC-0610-0653-B7D0F934EF12" categoriePret="1" searchText="51084"/>	xml
@FltStocPred	0	int
@searchText	51084	varchar
@subunitate	1	varchar
@gestiune		varchar
@categoriePret	1	int
@aplicatie		varchar
@subtip		varchar
@utilizator	MAGAZIN_NT	varchar
@GESTPV	211.1	varchar
@listaGestiuni	211.1;211;	varchar
@lista_gestiuni		int
@gestuniUtiliz	(table)	table
@nomencl	(table)	table
*/
declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="1" data="12/20/2012" inXML="0" UID="56E1C674-B8FC-0610-0653-B7D0F934EF12" categoriePret="1" searchText=""/>')
exec wACNomenclatorPv @sesiune='6856ED4011C90',@parXML=@p2