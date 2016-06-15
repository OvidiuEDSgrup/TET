
create procedure wIaSurse @sesiune varchar(50), @parXML xml 
as  

declare @cod varchar(8) , @denumire varchar(50) ,@f_denumire varchar(50),@f_cod varchar(50),@userASiS varchar(50)
    
		 select @cod=isnull(@parXML.value('(/row/@cod)[1]','varchar(80)'),''),
				@denumire=isnull(@parXML.value('(/row/@denumire)[1]','varchar(80)'),''),
				@f_denumire=isnull(@parXML.value('(/row/@f_denumire)[1]','varchar(80)'),''),
				@f_cod=isnull(@parXML.value('(/row/@f_cod)[1]','varchar(80)'),'')
  
             
         select RTRIM(cod) as cod , RTRIM(denumire) as denumire from surse 
               where isnull(cod,'') like '%'+ISNULL(@f_cod,'')+'%'
                     and isnull(denumire,'') like '%'+ISNULL(@f_denumire,'')+'%'
                     
  
  
 for xml raw
		 
		 
