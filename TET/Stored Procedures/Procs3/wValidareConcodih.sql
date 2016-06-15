--***
Create 
procedure wValidareConcodih (@sesiune varchar(50), @document xml)
as 
begin
	declare @marca varchar(6), @data datetime, @tipconcediu varchar(2), @datainceput datetime, @datasfarsit datetime, 
	@Plecat int, @Data_plec datetime, @ZileCO int, @ZileCOcuv int, @ZileCOcuvAnAnt int, 
	@ZileCOefect int, @ZileCOefectAnCrt int, @ZileCOefectAnAnt int, @mesaj varchar(200)
	set @marca=isnull(@document.value('(/row/row/@marca)[1]', 'varchar(6)'), isnull(@document.value('(/row/@marca)[1]', 'varchar(6)'), ''))
	set @data=isnull(@document.value('(/row/row/@data)[1]', 'datetime'), isnull(@document.value('(/row/@data)[1]', 'datetime'), ''))
	set @tipconcediu=isnull(@document.value('(/row/row/@tipconcediu)[1]', 'varchar(2)'),'')
	set @datainceput=isnull(@document.value('(/row/row/@datainceput)[1]','datetime'),'')
	set @datasfarsit=isnull(@document.value('(/row/row/@datasfarsit)[1]','datetime'),'')
	select @Plecat=convert(int,Loc_ramas_vacant), @Data_plec=Data_plec from personal where marca=@marca

	if @document.exist('/row/row')=1 and @marca not in (select marca from personal)
	begin
		raiserror('Marca inexistenta!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @Plecat=1 and @Data_plec<dbo.bom(@data)
	begin
		set @mesaj='Salariatul selectat este plecat din unitate la '+convert(char(10),@Data_plec,103)+' !'
		raiserror(@mesaj,11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @tipconcediu in ('7','8')
	begin
		raiserror('Nu se poate adauga/modifica un concediu de odihna cu tip 7 sau 8. Acestea sunt generate din luni anterioare!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @tipconcediu = ''
	begin
		raiserror('Tip concediu necompletat!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and dbo.eom(@datainceput)<>dbo.eom(@data)
	begin
		raiserror('Data de inceput trebuie sa fie in luna de lucru!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and dbo.eom(@datasfarsit)<dbo.eom(@data)
	begin
		raiserror('Data de sfarsit trebuie sa fie in luna de lucru!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @datasfarsit<@datainceput
	begin
		raiserror('Data de sfarsit este mai mica decat data inceput!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and dbo.eom(@datasfarsit)>dbo.eom(@data)
		select 'Daca data de sfarsit este mai mare decat ultima zi a lunii de lucru, se vor genera concedii de odihna pe luna/lunile urmatoare!' as textMesaj for xml raw, root('Mesaje')

	Set @ZileCO=dbo.Zile_lucratoare(@datainceput,@datasfarsit)
	if OBJECT_ID('tempdb..#zileCOcuv') is not null 
		drop table #zileCOcuv
	create table #zileCOcuv (marca varchar(6), zile int)
	exec pZileCOcuvenite @marca=@marca, @data=@data, @Calcul_pana_la_luna_curenta=0
	Select @ZileCOcuv=zile from #zileCOcuv
	Select @ZileCOcuv=isnull(@ZileCOcuv,0)

	Select @ZileCOcuvAnAnt=isnull(coef_invalid,0) from istPers where Data=dbo.BOY(@datainceput)-1 and Marca=@marca
	select @ZileCOefect=dbo.zile_CO_efectuate(@marca, @data, @datainceput,'1345678') 
	select @ZileCOefectAnCrt=dbo.zile_CO_efectuate(@marca, @data, @datainceput,'1357') 
	select @ZileCOefectAnAnt=dbo.zile_CO_efectuate(@marca, @data, @datainceput,'468') 
	if @document.exist('/row/row')=1 and charindex(@tipconcediu,'1357')<>0 and @ZileCOefectAnCrt+@ZileCO>@ZileCOcuv
		select 'Numarul de zile de concediu efectuate (din cele cuvenite pt. anul curent): '+convert(char(3),@ZileCOefectAnCrt+@ZileCO)+' depaseste '+
		'numarul de zile cuvenite pt. anul curent: '+convert(char(3),@ZileCOcuv)+'!' as textMesaj for xml raw, root('Mesaje')
	if @document.exist('/row/row')=1 and charindex(@tipconcediu,'468')<>0 and @ZileCOefectAnAnt+@ZileCO>@ZileCOcuvAnAnt
		select 'Numarul de zile de concediu efectuate (din cele ramase din anul anterior): '+convert(char(3),@ZileCOefectAnAnt+@ZileCO)+' depaseste '+
		'numarul de zile ramase din anul anterior: '+convert(char(3),@ZileCOcuvAnAnt)+'!' as textMesaj for xml raw, root('Mesaje')
	if @document.exist('/row/row')=1 and charindex(@tipconcediu,'2E')=0 and @ZileCOefect+@ZileCO>@ZileCOcuv+@ZileCOcuvAnAnt
		select 'Numarul de zile de concediu efectuate: '+convert(char(3),@ZileCOefect+@ZileCO)+' depaseste '+
		'numarul de zile de CO cuvenite: '+convert(char(3),@ZileCOcuv)+'  si ramase din anul anterior: '+convert(char(3),@ZileCOcuvAnAnt)+'!' as textMesaj for xml raw, root('Mesaje')
end
