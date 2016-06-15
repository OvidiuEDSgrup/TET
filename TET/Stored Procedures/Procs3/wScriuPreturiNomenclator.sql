
create procedure wScriuPreturiNomenclator @sesiune varchar(50), @parXML xml
as
begin try
	Declare 
		@update bit, @cod varchar(20),@data datetime,@pret_cu_amanuntul decimal(12,3),@pret_vanzare decimal(12,3),@catpret varchar(10),@tippret varchar(1),@utilizator varchar(50),@datasuperioara datetime,
		@orainferioara char(8),@orasuperioara char(8), @tip_categorie int,@o_pret_vanzare decimal(12,3),@o_pret_cu_amanuntul decimal(12,3), @um varchar(3)

	SELECT
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@cod = upper(@parXML.value('(/row/@cod)[1]','varchar(20)')),
		@catpret= @parXML.value('(/row/row/@catpret)[1]','varchar(20)'),
		@tippret = @parXML.value('(/row/row/@tippret)[1]','varchar(20)'),
		@data= @parXML.value('(/row/row/@data_inferioara)[1]','datetime'),
		@datasuperioara= @parXML.value('(/row/row/@data_superioara)[1]','datetime'),
		@pret_cu_amanuntul= @parXML.value('(/row/row/@pret_cu_amanuntul)[1]','decimal(12,3)'),
		@um= @parXML.value('(/row/row/@um)[1]','varchar(3)'),
		@pret_vanzare= @parXML.value('(/row/row/@pret_vanzare)[1]','decimal(12,3)'),
		@o_pret_vanzare= @parXML.value('(/row/row/@o_pret_vanzare)[1]','decimal(12,3)'),
		@o_pret_cu_amanuntul= @parXML.value('(/row/row/@o_pret_cu_amanuntul)[1]','decimal(12,3)')

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	if @utilizator is null
		return

	--identificare tip categorie
	select @tip_categorie=tip_categorie from categpret where categorie=@catpret

	--se calculeaza pretul de vanzare prin extragerea tva-ului din pretul cu amanuntul, doar daca tipul categoriei nu este 3(discount)
	declare @cota_tva decimal(12,3)
	set @cota_tva=isnull((select top 1 Cota_TVA from nomencl where cod=@cod),0)

	if @pret_vanzare is null and @pret_cu_amanuntul is null
		raiserror('Este obligatoriu sa completati un pret',16,1) 

	if @pret_vanzare is null and @tip_categorie=3
		raiserror('Este obligatoriu sa completati  pret vanzare/discount pentru o categorie de tip discount',16,1) 
	
	if (isnull(@pret_vanzare,0)=0 OR @pret_cu_amanuntul <> @o_pret_cu_amanuntul) and @tip_categorie<>3 and isnull(@pret_cu_amanuntul,0)>0
	begin
		set @pret_vanzare=round(@pret_cu_amanuntul/(100.00+@cota_tva)*100.00,3)
		set @o_pret_vanzare=@pret_vanzare
	end
	if (isnull(@pret_cu_amanuntul,0)=0 or @o_pret_vanzare!=@pret_vanzare) and isnull(@pret_vanzare,0)>0
		set @pret_cu_amanuntul=(case when @tip_categorie=3 then 0 else round(@pret_vanzare*(100.00+@cota_tva)/100.00,3) end)

	if @tippret='3' --Validari specifice orei
	begin
		select @orainferioara=isnull(@parXML.value('(/row/row/@orainferioara)[1]','char(8)'),''),
					@orasuperioara=isnull(@parXML.value('(/row/row/@orasuperioara)[1]','char(8)'),'')
		if not (isdate(@orainferioara)=1 and isdate(@orasuperioara)=1)
			raiserror('Introduceti ora in formatul corect HH:MM:SS',16,0)
		set @orainferioara=replace(@orainferioara,':','')
		set @orasuperioara=replace(@orasuperioara,':','')
	end
	else
	begin
		set @orainferioara=''
		set @orasuperioara=''
	end

	declare @tip varchar(1)

		if @update=1  --se va sterge linia cu pretul respectiv deoarece se poate schimba data, adica cheia
		begin  
			declare @o_cod varchar(20),@o_data datetime,@o_categpret varchar(10),@o_tippret varchar(10)
			Set @o_cod= @parXML.value('(/row/row/@o_cod)[1]','varchar(20)')
			Set @o_data= @parXML.value('(/row/row/@o_data_inferioara)[1]','datetime')
			Set @o_categpret= @parXML.value('(/row/row/@o_categorie)[1]','varchar(10)')
			Set @o_tippret= @parXML.value('(/row/row/@o_tippret)[1]','varchar(10)')
		
			delete from preturi where Cod_produs= @o_cod and preturi.Data_inferioara=@o_data and preturi.UM=@catpret and preturi.Tip_pret=@tippret and ISNULL(umprodus,'')=ISNULL(@um,'')
		end  

		--se cauta ultimul pret pana la mine si se pune update cu o zi inainte
		declare @lastdate datetime
		set @lastdate=(select top 1 data_superioara from preturi where
			Cod_produs= @cod and preturi.UM=@catpret and preturi.Tip_pret=@tippret and Data_inferioara<@data and ISNULL(umprodus,'')=ISNULL(@um,'')
			order by Data_superioara desc)

		if @lastdate is not null and @tippret in ('1','9')
		begin
			update preturi set Data_superioara=DATEADD(DAY,-1,@data)
			where Cod_produs= @cod and preturi.Data_superioara=@lastdate and preturi.UM=@catpret and preturi.Tip_pret=@tippret and ISNULL(umprodus,'')=ISNULL(@um,'')
		end
	
		--se cauta daca exista pret dupa data ceruta si se pune data superioara data inferioara a pretului de dupa -1 zi
		if @tippret in ('1','9')
		begin
			set @lastdate=(select top 1 data_inferioara from preturi where
			Cod_produs= @cod and preturi.UM=@catpret and preturi.Tip_pret=@tippret and Data_inferioara>@data and ISNULL(umprodus,'')=ISNULL(@um,'')
			order by Data_superioara desc)
	
			declare @datasup datetime
			if @lastdate is not null
				set @datasup=DATEADD(DAY,-1,@lastdate)
			else
				set @datasup='01/01/2999'
		end
		else if @tippret='2' or @tippret='3' --Pentru pret promotional data
			set @datasup=@datasuperioara

		/*Daca exista pe aceleasi date va fi inlocuit*/
		delete from preturi
			where cod_produs=@cod and tip_pret=@tippret and um=@catpret and data_inferioara=@data and ISNULL(umprodus,'')=ISNULL(@um,'')

		insert into preturi (Cod_produs,UM,Tip_pret,Data_inferioara,Ora_inferioara,Data_superioara,Ora_superioara,Pret_vanzare,Pret_cu_amanuntul,Utilizator,Data_operarii,Ora_operarii, umprodus)
		values (@cod,@catpret,@tippret,@data,@orainferioara,@datasup,@orasuperioara,@pret_vanzare,@pret_cu_amanuntul,@utilizator,GETDATE(),'', @um)

		if exists (select 1 from sys.objects where name='wScriuPreturiNomenclatorSP' and type='P')  
			exec wScriuPreturiNomenclatorSP @sesiune, @parXML
end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()+ ' (wScriuPreturiNomenclator)'
	raiserror(@mesaj, 11, 1)	
end catch
