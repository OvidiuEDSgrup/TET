--***
create procedure wStergPozcon @sesiune varchar(50), @parXML xml  
as  
  
Declare @mesajeroare varchar(100), @eroare xml, @TermPeSurse int, @numarpoz int  
declare @iDoc int 

begin try
	--select @TermPeSurse=Val_logica from par where tip_parametru='UC' and parametru='POZSURSE'
	exec luare_date_par 'UC', 'POZSURSE', @TermPeSurse output,0, 0
	exec sp_xml_preparedocument @iDoc output, @parXML  
	set @termpesurse=isnull(@TermPeSurse,0)    
	
	select @mesajeroare= 
	(case 
	when exists (select 1 from con c, OPENXML (@iDoc, '/row')  
	 WITH  
	 (  
	  subunitate char(9) '@subunitate',   
	  tip char(2) '@tip',   
	  numar char(20) '@numar', 
	  tert char(13) '@tert',
	  cod char(20) '@cod',  
	  data datetime '@data',    
	  numar_pozitie int '@numarpozitie'  
	 ) as dx  
	where c.subunitate=dx.subunitate and c.tip=dx.tip and c.contract=dx.numar and c.tert=dx.tert and c.data=convert(datetime,dx.data,103) and stare>'0') 
		then 'wStergPozcon:Starea comenzii nu este 0-'+isnull((select rtrim(val_alfanumerica) from par where tip_parametru='UC' and parametru='STAREBK0'),' operat')+'!' 
	else '' end)

	if @mesajeroare<>'' 	
		raiserror(@mesajeroare, 11, 1)
	declare @sub char(9),@tip char(2),@num char(20),@ter char(13),@co char(20),@da datetime,
			@tm datetime,@ca varchar(10),@pr varchar(10), @mp char(8), @nrpoz int, @subtip char(2)
	set @sub=isnull(@parXML.value('(/row/@subunitate)[1]', 'char(9)'),'1')
	set @tip=isnull(@parXML.value('(/row/@tip)[1]', 'char(2)'),'BF')
	set @num=isnull(@parXML.value('(/row/@numar)[1]', 'char(20)'),'')
	set @ter=isnull(@parXML.value('(/row/@tert)[1]', 'char(13)'),'')
	set @co=isnull(@parXML.value('(/row/@cod)[1]', 'char(20)'),'')
	set @mp=isnull(@parXML.value('(/row/@modplata)[1]', 'char(8)'),'')
	set @da=isnull(@parXML.value('(/row/@data)[1]', 'datetime'),'1921-01-01')
	set @tm=isnull(@parXML.value('(/row/@termene)[1]', 'datetime'),'1921-01-01')
	set @ca=isnull(@parXML.value('(/row/@Tcantitate)[1]', 'varchar(10)'),'1921-01-01')
	set @pr=isnull(@parXML.value('(/row/@Tpret)[1]', 'varchar(10)'),'')
	set @nrpoz=isnull(@parXML.value('(/row/@numarpozitie)[1]', 'int'),0)
	set @subtip=isnull(@parXML.value('(/row/row/@subtip)[1]', 'char(2)'),'')

	if @tip='BF'	
	begin
		set @numarpoz=isnull((select max(numar_pozitie) 
				from pozcon 
				where tip=@tip and contract=@num and tert=@ter and data=@da and subunitate=@Sub and cod=@co and (mod_de_plata=@mp or @mp='')),0)
		
		--nu sterg din pozcon daca codul - termenul care se doreste sters a fost facturat
		if exists (select 1 from termene tr, pozcon pc 
				where pc.subunitate=tr.subunitate and pc.contract=tr.contract and pc.data=tr.data and pc.tert=tr.tert
					and tr.subunitate=@sub and tr.data=@da and tr.contract=@num  and tr.tert=@ter
					and tr.cod=(case when @TermPeSurse=0 then @co else ltrim(str(@numarpoz)) end) 
					and (@subtip='TE' and tr.Termen=@tm and (abs(tr.Cant_realizata)>0.01 ) or (@subtip='BF' and abs(pc.cant_Realizata)>0.01)))
			raiserror('De pe acest termen/cod s-a facturat, operatie de stergere nepermisa!',16,1)
	    
		if @subtip='TE' --stergere termene
		begin
			delete termene
			where subunitate=@sub and tip=@tip and Contract=@num and Tert=@ter 
			and	Cod=(case when @TermPeSurse=0 then @co else ltrim(str(@numarpoz)) end) and data=@da and Termen=@tm and Cantitate=@ca 
		end
		else 
			if @subtip='BF' --stergere cod cu termenele aferente lui
			begin
				delete termene
				where subunitate=@sub and tip=@tip and Contract=@num and Tert=@ter 
					and Cod=(case when @TermPeSurse=0 then @co else ltrim(str(@numarpoz)) end)and data=@da 
			end
		
		--Stergere din POZCON si refacere cantitate
		if not exists (select * from termene
			where subunitate = @sub and tip = @tip and Contract = @num and Tert = @ter 
			and Cod = (case when @TermPeSurse=0 then @co else ltrim(str(@numarpoz)) end) and data = @da) 
			delete pozcon
			where subunitate in (@sub, 'EXPAND', 'EXPAND2') and tip=@tip and Contract=@num and Tert=@ter and Cod=@co and data=@da and (Mod_de_plata=@mp or @mp='')
		--
		update pozcon set cantitate=isnull((select SUM(cantitate) from Termene  where Subunitate=@sub and tip=@tip and contract=@num 
										and tert=@ter and Data=@da and cod=(case when @TermPeSurse=0 then @co else ltrim(str(@numarpoz)) end)),0)
		where subunitate=@sub and tip=@tip and Contract=@num and Tert=@ter and Cod=@co  and data=@da and (Mod_de_plata=@mp or @mp='')
		
		--Sterg din CON: NU!
		if 1=0 and not exists (select * from termene
				where subunitate = @sub and tip = @tip and Contract = @num and Tert = @ter and data = @da)	
			delete con where subunitate=@sub and tip=@tip and Contract=@num and Tert=@ter and data=@da	
		
		-->pt BF-uri cantitatile si valorile din con se vor calcula din termene
		update con set Total_contractat=p.total_contractat,Total_TVA=p.total_tva
		from 
			(select isnull(SUM(round(t.cantitate*t.pret*(1.00 - p1.discount / 100.00),2)),0) as total_contractat,
					isnull(SUM(round(p1.Suma_TVA,2)),0) as total_tva
					from pozcon p1
						inner join termene t on p1.subunitate=@Sub and p1.tip=@tip and p1.contract=@num and p1.tert=@ter and p1.data=@da 
							and t.Subunitate=p1.Subunitate and t.Tip=p1.tip and t.Contract=p1.Contract and t.Tert=p1.Tert 
							and t.cod=(case when @TermPeSurse=0 then p1.cod else ltrim(str(p1.Numar_pozitie)) end)					
					where p1.subunitate=@Sub and p1.tip=@tip and p1.contract=@num and p1.tert=@ter and p1.data=@da) p
		where subunitate=@Sub and tip=@tip and contract=@num and tert=@ter and data=@da and @tip='BF'
	end	
	
	else -->tip FA,FC,BK ->lucru fara termene
	begin
		delete pozcon
		where subunitate in (@Sub, 'EXPAND', 'EXPAND2') and tip=@tip and Contract=@num and Tert=@ter and Cod=@co and data=@da 
			and (@nrpoz is null or Numar_pozitie=@nrpoz)
		
		-->pt FA,BK,FC-uri cantitatile si valorile din con se vor calcula din pozcon
		update con set Total_contractat=p.total_contractat+(case when tip in ('FC','BK','BP','FO') then p.total_tva else 0 end),Total_TVA=p.total_tva
		from 
			(select isnull(SUM(round(cantitate*pret*(1.00 - discount / 100.00),2)),0) as total_contractat,
					isnull(SUM(round(Suma_TVA,2)),0) as total_tva
				from pozcon
				where subunitate=@Sub and tip=@tip and contract=@num and tert=@ter and data=@da) p
		where subunitate=@Sub and tip=@tip and contract=@num and tert=@ter and data=@da
	end
	
	exec sp_xml_removedocument @iDoc   
	declare @docXMLIaPozCon xml
	set @docXMLIaPozCon = '<row subunitate="' + rtrim(@sub) + '" tip="' + rtrim(@tip) + '" numar="' + rtrim(@num) + '" data="' + convert(char(10), @da, 101) +'" tert="'+rtrim(@ter)+'"/>'
	select @docXMLIaPozCon 
	exec wIaPozCon @sesiune=@sesiune, @parXML=@docxmliapozCon

end try
begin catch
	declare @mesaj varchar(500)
	set @mesaj = '(wStergPozCon):'+ERROR_MESSAGE()
	raiserror(@mesaj, 16, 1)
end catch
