CREATE procedure wIaPotentialiClienti @sesiune varchar(50), @parXML xml  
as 

	declare
		@f_denumire varchar(200), @f_cod_fiscal varchar(100), @f_localitate varchar(100), @f_judet varchar(200), @f_note varchar(200), @f_supervizor varchar(100), @idPotential int

	select
		@f_denumire= '%'+ ISNULL(replace(@parXML.value('(/*/@f_denumire)[1]','varchar(200)'),' ','%'),'')+'%',
		@f_cod_fiscal= '%'+ ISNULL(@parXML.value('(/*/@f_cod_fiscal)[1]','varchar(200)'),'')+'%',
		@f_localitate= '%'+ ISNULL(@parXML.value('(/*/@f_localitate)[1]','varchar(200)'),'')+'%',
		@f_judet= '%'+ ISNULL(@parXML.value('(/*/@f_judet)[1]','varchar(200)'),'')+'%',
		@f_note= '%'+ ISNULL(@parXML.value('(/*/@f_note)[1]','varchar(200)'),'')+'%',
		@f_supervizor= '%'+ ISNULL(@parXML.value('(/*/@f_supervizor)[1]','varchar(200)'),'')+'%',
		@idPotential=@parXML.value('(/*/@idPotential)[1]','int')



	select top 100
		rtrim(p.denumire) dentert, p.cod_fiscal cod_fiscal, p.detalii detalii, p.idPotential idPotential, p.note note, rtrim(u.Nume) supervizor,
		rtrim(l.oras) denlocalitate, p.cod_localitate localitate, rtrim(j.denumire) denjudet, rtrim(j.cod_judet) judet,
		ISNULL (pzo.nr,0) oportunitati, (case when pzo.nr+pzs.nr=0 then '#C0C0C0' end ) as culoare, ISNULL (pzs.nr,0) sesizari
	from Potentiali p
	LEFT JOIN Localitati l on p.cod_localitate=l.cod_oras
	LEFT JOIN Judete j on j.cod_judet=l.cod_judet
	LEFT JOIN utilizatori u on u.ID=p.supervizor
	OUTER APPLY(select count(1)  nr from Oportunitati where idPotential=p.idPotential) pzo
	OUTER APPLY(select count(1)  nr from SesizariCRM s where idPotential=p.idPotential) pzs
	where
		p.denumire like @f_denumire and
		p.cod_fiscal like @f_cod_fiscal and
		p.note like @f_note and
		l.oras like @f_localitate and
		j.denumire like @f_judet and
		u.Nume like @f_supervizor and
		(@idPotential is null or p.idPotential=@idPotential)
	order by p.data_operatii desc, pzo.nr+pzs.nr desc
	for xml raw, root('Date')


	select '1' as areDetaliiXml
	for xml raw, root('Mesaje')

