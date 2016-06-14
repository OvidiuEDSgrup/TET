--***
if exists (select * from sysobjects where name ='yso_tr_validFacturi' and xtype='TR')
	drop trigger yso_tr_validFacturi

go
--***
create  trigger yso_tr_validFacturi on facturi for insert,update NOT FOR REPLICATION as
DECLARE @factbil int, @nrRanduri int,@mesaj varchar(255)
set @factbil=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='FACTBIL'),0)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN
	
--IF isnull((select top 1 t.is_disabled from sys.triggers t where t.name like 'tr_validFacturi'),1)=1 
--	RETURN
IF (select count(distinct tert) from inserted where inserted.tert<>'' and inserted.Tip=0x46 and abs(inserted.Sold)>=0.001)<>1
	RETURN

begin try
	DECLARE @msgErr VARCHAR(2000), @tertErr VARCHAR(20), @factErr varchar(20)
/*
	if UPDATE(factura) or UPDATE(tert) or UPDATE(tip) --Verificam consistenta tertilor 
	begin	
		select top 1 @factErr=f.Factura, @tertErr=f.tert from inserted i
			left outer join facturi f on i.Subunitate=f.Subunitate and i.Tip=f.Tip and i.Factura=f.Factura 
				and i.Tert<>f.tert and abs(i.Valoare)+ABS(i.Achitat)>=0.001
		WHERE i.Tip=0x46 and f.Tert is not null
		
		if @tertErr is not null
			BEGIN
				SET @msgErr='(facturi.yso_tr_validFacturi): '+char(13)
					+'Eroare operare! Factura ('+rtrim(@factErr)+') deja existenta la tertul ('+rtrim(@tertErr)+')'
				raiserror(@msgErr,16,1)
			END
	end  
*/
	if UPDATE(sold)--Ghita, 09.07.2012: Verificare sold maxim beneficiar
	begin
		declare @valFacturi float, @soldmaxim float, @sold float, @zileScadDepasite bit, @dentertErr varchar(200)
		set @tertErr=null
/*		
		declare @test xml,@detaliu xml
		set @test=(select i.Tert,s.sursa
				,soldv=convert(decimal(17,2),isnull(s.sold,0))
				,soldi=convert(decimal(17,2),isnull(i.sold,0))
				,soldm=convert(decimal(17,2),isnull(t.Sold_maxim_ca_beneficiar,0))
			from (select subunitate,tert,sold,sursa='F' from facturi where facturi.Tip=0x46 and abs(facturi.Sold)>=0.001
					union all select subunitate,tert,sold,sursa='E' from efecte where efecte.Tip='I' and abs(efecte.Sold)>=0.001
					union all select s.subunitate,ISNULL(pc.tert,s.Comanda),s.Stoc*convert(decimal(15,2),s.Pret_cu_amanuntul),sursa='S'
						from stocuri s 
							inner join nomencl n on s.cod=n.cod
							left join pozcon pc on pc.Subunitate=s.Subunitate and pc.Tip='BK' and pc.Contract=s.Contract 
								and pc.Cod=s.Cod
							inner join terti on terti.Subunitate=s.Subunitate and terti.tert=ISNULL(pc.tert,s.Comanda)
						where s.Cod_gestiune='700' and s.stoc>=0.001) s
			inner join 
				(select i1.Subunitate, i1.Tert, sold=sum(i1.Sold) 
				from (select subunitate,tert,sold from inserted where inserted.Tip=0x46 and abs(inserted.Sold)>=0.001
					union all select subunitate,tert,-sold from deleted where deleted.Tip=0x46 and abs(deleted.Sold)>=0.001) i1
				group by i1.Subunitate, i1.Tert
				having SUM(i1.Sold)>0) i on i.Subunitate=s.Subunitate and i.Tert=s.Tert 
			left join terti t on t.Subunitate=i.Subunitate and t.Tert=i.Tert for xml raw)
*/		
		select top 1 @tertErr=i.Tert, @dentertErr=max(t.Denumire)
			,@sold=sum(f.sold),@valFacturi=max(i.sold),@soldmaxim=MAX(t.Sold_maxim_ca_beneficiar)
		from (select s.Subunitate, s.Tert, sold=sum(s.Sold) 
				from (select subunitate,tert,sold from facturi where facturi.Tip=0x46 and abs(facturi.Sold)>=0.001
					union all select subunitate,tert,sold from efecte where efecte.Tip='I' and abs(efecte.Sold)>=0.001
					union all select s.subunitate,ISNULL(pc.tert,s.Comanda),s.Stoc*convert(decimal(15,2),s.Pret_cu_amanuntul)
						from stocuri s 
							inner join nomencl n on s.cod=n.cod
							left join pozcon pc on pc.Subunitate=s.Subunitate and pc.Tip='BK' and pc.Contract=s.Contract 
								and pc.Cod=s.Cod
							inner join terti on terti.Subunitate=s.Subunitate and terti.tert=ISNULL(pc.tert,s.Comanda)
						where s.Cod_gestiune like '700%' and s.stoc>=0.001) s
				group by s.Subunitate, s.Tert
				having SUM(s.Sold)>0) f
			inner join 
				(select i1.Subunitate, i1.Tert, sold=sum(i1.Sold) 
				from (select subunitate,tert,sold from inserted where inserted.Tip=0x46 and abs(inserted.Sold)>=0.001
					union all select subunitate,tert,-sold from deleted where deleted.Tip=0x46 and abs(deleted.Sold)>=0.001) i1
				group by i1.Subunitate, i1.Tert
				having SUM(i1.Sold)>0) i on i.Subunitate=f.Subunitate and i.Tert=f.Tert 
			left join terti t on t.Subunitate=i.Subunitate and t.Tert=i.Tert
		group by i.Tert
		having isnull(sum(f.sold),0)>isnull(nullif(max(t.Sold_maxim_ca_beneficiar),0),999999999.00)
		
		if @tertErr is not null
		begin
			set @msgErr='Tertul '+RTRIM(@tertErr)+' '+rtrim(@denTertErr)
			if @zileScadDepasite=1
				set @msgErr = isnull(@msgErr+CHAR(13),'')+'Are facturi cu scadenta depasita.'
				
			set @msgErr = isnull(@msgErr+CHAR(13),'')+'Generarea facturii ar depasi soldul maxim permis: '
				+CONVERT(varchar(30), convert(decimal(12,2), @soldmaxim)) + ' RON.'
				+CHAR(13)+ 'Soldul anterior: '+ CONVERT(varchar(30), convert(decimal(12,2), isnull(@sold,0)-@valFacturi)) + ' RON.'
				+CHAR(13)+ 'Valoarea curenta: '+ CONVERT(varchar(30), convert(decimal(12,2), @valFacturi)) + ' RON.'
				
			raiserror(@msgErr,16,1)
		end
	end

end try
begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = '(facturi.yso_tr_ValidFacturi): '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
--select * from conturi