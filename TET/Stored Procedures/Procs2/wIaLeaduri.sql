
create procedure wIaLeaduri @sesiune varchar(50), @parXML XML
as
	declare
		@f_domeniu varchar(200),@f_note varchar(200),@f_nume varchar(200),@f_nume_firma varchar(200),@f_status varchar(200),@f_supervizor varchar(200),@f_topic varchar(200)
	
	select 
		@f_domeniu='%'+ISNULL(REPLACE(@parXML.value('(/*/@f_domeniu)[1]','varchar(200)'),' ','%'),'%')+'%',
		@f_note='%'+ISNULL(REPLACE(@parXML.value('(/*/@f_note)[1]','varchar(200)'),' ','%'),'%')+'%',
		@f_nume='%'+ISNULL(REPLACE(@parXML.value('(/*/@f_nume)[1]','varchar(200)'),' ','%'),'%')+'%',
		@f_nume_firma='%'+ISNULL(REPLACE(@parXML.value('(/*/@f_nume_firma)[1]','varchar(200)'),' ','%'),'%')+'%',
		@f_status='%'+ISNULL(REPLACE(@parXML.value('(/*/@f_status)[1]','varchar(200)'),' ','%'),'%')+'%',
		@f_supervizor='%'+ISNULL(REPLACE(@parXML.value('(/*/@f_supervizor)[1]','varchar(200)'),' ','%'),'%')+'%',
		@f_topic='%'+ISNULL(REPLACE(@parXML.value('(/*/@f_topic)[1]','varchar(200)'),' ','%'),'%')+'%'
	
	select top 100
		l.idLead idLead, l.topic topic, l.nume nume, l.domeniu_activitate domeniu_activitate, l.email email, l.note note, l.telefon telefon,
		l.denumire_firma dentert, convert(varchar(10), l.data_operarii, 101) data, l.supervizor supervizor, rtrim(u.nume) densupervizor,
		l.detalii detalii, l.stare stare
	from Leaduri l	
	LEFT join utilizatori u on u.id=l.supervizor
	where
		(l.domeniu_activitate like @f_domeniu) and
		(l.note like @f_note) and
		(l.nume like @f_nume) and
		(l.denumire_firma like @f_nume_firma ) and
		(l.stare like @f_status) and
		(l.supervizor like @f_supervizor) and
		(l.topic like @f_topic)

	order by newid()
	for xml raw, root('Date')

	select 1 as areDetaliiXml for xml raw, root('Mesaje')
