
--***

create procedure wIaContinutD394 @sesiune varchar(50), @parXML xml
as
begin try
	declare 
		@utilizator varchar(20), @data datetime,
		@f_tert varchar(80), @f_tip varchar(1),
		@mesaj varchar(500)

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	select
		@data = @parXML.value('(/row/@datalunii)[1]','datetime'),
		@f_tert = isnull(@parXML.value('(/row/@f_tert)[1]','varchar(80)'),''),
		@f_tip = isnull(@parXML.value('(/row/@f_tip)[1]','varchar(1)'),'')

	select
		rtrim(T.N.value('(@cuiP)[1]','varchar(80)')) as tert,
		rtrim(T.N.value('(@denP)[1]','varchar(200)')) as dentert,
		(case when rtrim(T.N.value('(@tip)[1]','varchar(1)')) = 'A' then 'Achizitie' else 'Livrare' end) as dentip_op,
		T.N.value('(@nrFact)[1]','int') as nr_facturi,
		convert(decimal(15,3), T.N.value('(@baza)[1]','float')) as baza,
		convert(decimal(15,3), T.N.value('(@tva)[1]','float')) as tva
	from declaratii
	cross apply Continut.nodes('(/*/*)') as T(N)
	where Cod = '394'
		and isnull(T.N.value('(@cuiP)[1]','varchar(80)'),'') <> ''
		and Data = @data
		and (@f_tert = '' or rtrim(T.N.value('(@cuiP)[1]','varchar(80)'))
			like '%' + @f_tert + '%' or rtrim(T.N.value('(@denP)[1]','varchar(200)'))
			like '%' + @f_tert + '%')
		and (@f_tip = '' or rtrim(T.N.value('(@tip)[1]','varchar(1)'))
			like '%' + @f_tip + '%')
	for xml raw

end try
begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wIaContinutD394)'
	raiserror (@mesaj, 16, 1)
end catch

/*
	exec wIaContinutD394 '', '<row datalunii="2014-03-31"/>'
	select * from declaratii
*/
