--***
create procedure wScriuSalariiZilieri (@sesiune varchar(250), @parXML xml)
as

if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuSalariiZilieriSP')
begin
	declare @returnValue int
	exec @returnValue=wScriuSalariiZilieriSP @sesiune, @parXML output
	return @returnValue
end

begin try
	declare @userASiS char(10), @mesaj varchar(80),@update bit,
	@marca varchar(6), @lm varchar(9), @comanda varchar(13), @salor float, @orelucrate smallint, @venittotal float,
	@impozit float, @restdeplata float, @explicatii char(50), @dataplatii datetime, @denlm varchar(30), @dencomanda varchar(20),
	@tipsalor char(1), @nrcrt smallint, @data datetime, @datasus datetime, @datajos datetime, @nume varchar(20), @o_marca varchar(6), @lmantet varchar(9), @procent float,
	@docXMLIaSalariiZilieri xml
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	exec wValidareSalariiZilieri @sesiune, @parXML
	
	select  @data=ISNULL(@parXML.value('(/row/row/@data)[1]','datetime'),''),
		@marca=isnull(@parXML.value('(/row/row/@marca)[1]','varchar(6)'),''),
		@lm=isnull(@parXML.value('(/row/row/@lm)[1]','varchar(9)'),''),
		@lmantet=isnull(@parXML.value('(/row/@lmantet)[1]','varchar(9)'),''),
		@denlm=isnull(@parXML.value('(/row/@denlm)[1]','varchar(30)'),''),
		@salor=isnull(@parXML.value('(/row/row/@salor)[1]','float'),0),
		@nrcrt=isnull(@parXML.value('(/row/row/@nrcrt)[1]','smallint'),0),
		@comanda=isnull(@parXML.value('(/row/row/@comanda)[1]','varchar(13)'),''),
		@orelucrate=isnull(@parXML.value('(/row/row/@orelucrate)[1]','smallint'),0),
		@explicatii=isnull(@parXML.value('(/row/row/@explicatii)[1]','varchar(50)'),''),
		@dataplatii=ISNULL(@parXML.value('(/row/row/@dataplatii)[1]','datetime'),'01/01/1901'),
		@update=isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@nume=ISNULL(@parXML.value('(/row/@nume)[1]','varchar(20)'),''),
		@o_marca=isnull(@parXML.value('(/row/row/@o_marca)[1]','varchar(6)'),''),
		@datajos=dbo.Bom(@data), 
		@datasus=dbo.Eom(@data)
	select @procent=procent from impozit where Tip_impozit='P' and Numar_curent=1

	if ISNULL(@lm,'')='' 
		set @lm=(select loc_de_munca from Zilieri where Marca=@marca)
	if ISNULL(@comanda,'')='' 
		set @comanda=(select comanda from Zilieri where Marca=@marca)
	if ISNULL(@salor,0)=0 
		set @salor=(select Salar_orar from Zilieri where Marca=@marca)
		
	set @tipsalor=(select Tip_salar_orar from Zilieri where Marca=@marca)

	--calcul: venit total, impozit, rest de plata functie de tipul de salar orar brut/net
	if @tipsalor='B' 
	begin
		set @venittotal=@orelucrate * @salor
		exec calcul_impozit_salarii @venittotal, @impozit output, 0
		set @restdeplata=@venittotal-@impozit
	end
	else 
		if @tipsalor='N'	
		begin
			set @restdeplata=@orelucrate * @salor
			set @venittotal=round(@restdeplata * 100/(100-@procent),0)
			set @impozit=round(@venittotal-@restdeplata,0)
		end
			
	if @update=0 -- adaugare
	begin
		set @nrcrt=0
		select @nrcrt=MAX(isnull(Nr_curent,0)) from SalariiZilieri 
		where data between @datajos and @datasus and marca=@marca
		set @nrcrt=ISNULL(@nrcrt,0)
		set @nrcrt=@nrcrt+1
		insert into SalariiZilieri (data,marca,nr_curent,loc_de_munca,Comanda,ora_inceput,ora_sfarsit,Salar_orar,Ore_lucrate,diferenta_salar,Venit_total,Impozit,Rest_de_plata,
			Serie_registru,Nr_registru,Pagina_registru,Nr_curent_registru,Utilizator,Data_operarii,Ora_operarii,Explicatii, Data_platii)
		values (@data,@marca,@nrcrt,@lm,@comanda,'','',@salor,@orelucrate,'',@venittotal,@impozit,@restdeplata,'','','','',@userASiS,
			convert(datetime,convert(char(10),getdate(),104),104),RTrim(replace(convert(char(8),getdate(),108),':','')),@explicatii,@dataplatii)
	end
	else --modificare
	begin 
		update salariizilieri set marca=@marca, loc_de_munca=@lm, comanda=@comanda, salar_orar=@salor, ore_lucrate=@orelucrate, 
			venit_total=@venittotal, impozit=@impozit, rest_de_plata=@restdeplata, 
			utilizator=@userASiS, Data_operarii=convert(datetime,convert(char(10),getdate(),104),104), 
			ora_operarii=RTrim(replace(convert(char(8),getdate(),108),':','')), explicatii=@explicatii, Data_platii=@dataplatii
		where marca=@o_marca and rtrim(convert(char(10),Data,101))=@data and Nr_curent=@nrcrt
	end
	
	set @docXMLIaSalariiZilieri='<row lmantet="'+rtrim(@lmantet)+'" data="'+convert(char(10),dbo.eom(@data),101)+'"/>'
	exec wIaPozSalariiZilieri @sesiune=@sesiune, @parXML=@docXMLIaSalariiZilieri

end try
begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj,11,1)
end catch
