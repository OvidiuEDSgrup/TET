--***

create function fTextTvaLaIncasare(@data datetime,@Tert char(13),@factura char(20)) returns varchar(100)
as begin

/*
	select dbo.fTextTvaLaIncasare('05/01/2013','3504649','5234')
*/
declare @dataazi datetime,@tiptva char(1)
set @dataazi=@data

select @tiptva=
	isnull((select top 1 tip_tva from tvapeterti where tipf='B' and tert=@tert and factura=@factura),
		(select top 1 tip_tva from tvapeterti where tipf='B' and tert is null and dela<=@dataazi order by dela desc))

	declare @Mesaj char(40)

	if @tiptva='I'
		set @mesaj='FACTURA CU TVA LA INCASARE!'
	else
		set @mesaj=''
		
	return @mesaj
end
