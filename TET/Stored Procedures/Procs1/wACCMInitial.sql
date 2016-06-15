--***
Create procedure wACCMInitial @sesiune varchar(50),@parXML XML
as
if exists(select * from sysobjects where name='wACCMInitialSP' and type='P')
	exec wCMInitialSP @sesiune,@parXML
else      
begin
	declare @searchText varchar(80), @Marca varchar(6), @Data_inceput datetime
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), 
		@Marca=ISNULL(@parXML.value('(/row/@marca)[1]', 'varchar(6)'), ''), 
		@Data_inceput=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '') 

	set @searchText=REPLACE(@searchText, ' ', '%')
	
	select top 1 --100
		rtrim(e.Serie_certificat_CM)+' '+rtrim(e.Nr_certificat_CM) as cod,
		rtrim(convert(char(10),e.Data_inceput,103)) as info,  
		rtrim(e.Serie_certificat_CM)+' '+rtrim(e.Nr_certificat_CM)+' '+rtrim(d.denumire) as denumire
	from infoconmed e 
		left join conmed c on e.Data=c.Data and e.Marca=c.Marca and e.Data_inceput=c.Data_inceput
		left outer join fDiagnostic_CM() d on c.Tip_diagnostic=d.Tip_diagnostic
	where (e.Serie_certificat_CM like '%'+@searchText+'%' or e.Nr_certificat_CM like '%'+@searchText+'%')      
		and e.Marca=@Marca and c.Data_sfarsit<=@Data_inceput-1 and c.Zile_luna_anterioara=0 and e.Nr_certificat_CM_initial=''
	order by e.Data_inceput desc
	for xml raw      
end 
