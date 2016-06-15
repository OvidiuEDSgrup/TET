create function CaractereSpeciale (@sir varchar(8000)) 
RETURNS varchar(8000) 
AS 
BEGIN             
      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'À' COLLATE Latin1_General_CS_AS, 'A'             
  COLLATE Latin1_General_CS_AS)               
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'à' COLLATE Latin1_General_CS_AS, 'a'             
  COLLATE Latin1_General_CS_AS)      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Á' COLLATE Latin1_General_CS_AS, 'A'             
  COLLATE Latin1_General_CS_AS)           
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'á' COLLATE Latin1_General_CS_AS, 'a'             
  COLLATE Latin1_General_CS_AS)         
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Â' COLLATE Latin1_General_CS_AS,'A'             
  COLLATE Latin1_General_CS_AS)      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'â' COLLATE Latin1_General_CS_AS,'a'             
  COLLATE Latin1_General_CS_AS)         
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ă' COLLATE Latin1_General_CS_AS,'A'             
  COLLATE Latin1_General_CS_AS)      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ă' COLLATE Latin1_General_CS_AS,'a'             
  COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ä' COLLATE Latin1_General_CS_AS,'A'             
  COLLATE Latin1_General_CS_AS)      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ä' COLLATE Latin1_General_CS_AS,'a'             
  COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ç' COLLATE Latin1_General_CS_AS, 'C'            
  COLLATE Latin1_General_CS_AS)      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ç' COLLATE Latin1_General_CS_AS, 'c'            
  COLLATE Latin1_General_CS_AS)      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ć' COLLATE Latin1_General_CS_AS, 'C'            
  COLLATE Latin1_General_CS_AS)      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ć' COLLATE Latin1_General_CS_AS, 'c'            
  COLLATE Latin1_General_CS_AS)      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ĉ' COLLATE Latin1_General_CS_AS, 'C'            
  COLLATE Latin1_General_CS_AS)      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ĉ' COLLATE Latin1_General_CS_AS, 'c'            
  COLLATE Latin1_General_CS_AS)      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ċ' COLLATE Latin1_General_CS_AS, 'C'            
  COLLATE Latin1_General_CS_AS)      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ċ' COLLATE Latin1_General_CS_AS, 'c'            
  COLLATE Latin1_General_CS_AS)      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Č' COLLATE Latin1_General_CS_AS, 'C'            
  COLLATE Latin1_General_CS_AS)      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'č' COLLATE Latin1_General_CS_AS, 'c'            
  COLLATE Latin1_General_CS_AS)      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'É' COLLATE Latin1_General_CS_AS, 'E'            
  COLLATE Latin1_General_CS_AS)        
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'é' COLLATE Latin1_General_CS_AS, 'e'            
  COLLATE Latin1_General_CS_AS)         
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'È' COLLATE Latin1_General_CS_AS, 'E'            
  COLLATE Latin1_General_CS_AS)              
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'è' COLLATE Latin1_General_CS_AS, 'e'            
  COLLATE Latin1_General_CS_AS)        
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ê' COLLATE Latin1_General_CS_AS, 'E'            
  COLLATE Latin1_General_CS_AS)              
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ê' COLLATE Latin1_General_CS_AS, 'e'            
  COLLATE Latin1_General_CS_AS)             
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ë' COLLATE Latin1_General_CS_AS, 'E'            
  COLLATE Latin1_General_CS_AS)              
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ë' COLLATE Latin1_General_CS_AS, 'e'            
  COLLATE Latin1_General_CS_AS)          
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ĕ' COLLATE Latin1_General_CS_AS, 'E'            
  COLLATE Latin1_General_CS_AS)              
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ĕ' COLLATE Latin1_General_CS_AS, 'e'            
  COLLATE Latin1_General_CS_AS)        
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ę' COLLATE Latin1_General_CS_AS, 'E'            
  COLLATE Latin1_General_CS_AS)              
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ę' COLLATE Latin1_General_CS_AS, 'e'            
  COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ì' COLLATE Latin1_General_CS_AS, 'I'            
  COLLATE Latin1_General_CS_AS)              
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ì' COLLATE Latin1_General_CS_AS, 'i'            
  COLLATE Latin1_General_CS_AS)        
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Í' COLLATE Latin1_General_CS_AS, 'I'            
  COLLATE Latin1_General_CS_AS)              
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'í' COLLATE Latin1_General_CS_AS, 'i'            
  COLLATE Latin1_General_CS_AS)        
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Î' COLLATE Latin1_General_CS_AS,'I'             
  COLLATE Latin1_General_CS_AS)        
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'î' COLLATE Latin1_General_CS_AS,'i'             
  COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ï' COLLATE Latin1_General_CS_AS,'I'             
  COLLATE Latin1_General_CS_AS)        
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ï' COLLATE Latin1_General_CS_AS,'i'             
  COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ñ' COLLATE Latin1_General_CS_AS,'N'             
  COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ñ' COLLATE Latin1_General_CS_AS,'n'             
  COLLATE Latin1_General_CS_AS)         
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ń' COLLATE Latin1_General_CS_AS,'N'             
  COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ń' COLLATE Latin1_General_CS_AS,'n'             
  COLLATE Latin1_General_CS_AS)         
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ò' COLLATE Latin1_General_CS_AS,'O'             
  COLLATE Latin1_General_CS_AS)               
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ò' COLLATE Latin1_General_CS_AS, 'o'            
  COLLATE Latin1_General_CS_AS)        
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ó' COLLATE Latin1_General_CS_AS,'O'             
  COLLATE Latin1_General_CS_AS)               
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ó' COLLATE Latin1_General_CS_AS, 'o'            
  COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ô' COLLATE Latin1_General_CS_AS,'O'             
  COLLATE Latin1_General_CS_AS)               
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ô' COLLATE Latin1_General_CS_AS, 'o'            
  COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Õ' COLLATE Latin1_General_CS_AS,'O'             
  COLLATE Latin1_General_CS_AS)               
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'õ' COLLATE Latin1_General_CS_AS, 'o'            
  COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ö' COLLATE Latin1_General_CS_AS, 'O'            
  COLLATE Latin1_General_CS_AS)         
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ö' COLLATE Latin1_General_CS_AS, 'o'            
  COLLATE Latin1_General_CS_AS)        
  --set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ȍ' COLLATE Latin1_General_CS_AS, 'O'            
  --COLLATE Latin1_General_CS_AS)         
  --set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ȍ' COLLATE Latin1_General_CS_AS, 'o'            
  --COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ş' COLLATE Latin1_General_CS_AS,'s'             
  COLLATE Latin1_General_CS_AS)             
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ş' COLLATE Latin1_General_CS_AS,'S'             
  COLLATE Latin1_General_CS_AS)             
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ţ' COLLATE Latin1_General_CS_AS,'t'             
  COLLATE Latin1_General_CS_AS)             
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ţ' COLLATE Latin1_General_CS_AS,'T'             
  COLLATE Latin1_General_CS_AS)              
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ù' COLLATE Latin1_General_CS_AS, 'U'            
  COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ù' COLLATE Latin1_General_CS_AS, 'u'            
  COLLATE Latin1_General_CS_AS)         
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ú' COLLATE Latin1_General_CS_AS, 'U'            
  COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ú' COLLATE Latin1_General_CS_AS, 'u'            
  COLLATE Latin1_General_CS_AS)      
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Û' COLLATE Latin1_General_CS_AS, 'U'            
  COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'û' COLLATE Latin1_General_CS_AS, 'u'            
  COLLATE Latin1_General_CS_AS)          
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ü' COLLATE Latin1_General_CS_AS,'U'             
  COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ü' COLLATE Latin1_General_CS_AS, 'u'            
  COLLATE Latin1_General_CS_AS)        
  --set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ȕ' COLLATE Latin1_General_CS_AS,'U'             
  --COLLATE Latin1_General_CS_AS)       
  --set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ȕ' COLLATE Latin1_General_CS_AS, 'u'            
  --COLLATE Latin1_General_CS_AS)        
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'Ű' COLLATE Latin1_General_CS_AS,'U'             
  COLLATE Latin1_General_CS_AS)       
  set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'ű' COLLATE Latin1_General_CS_AS, 'u'            
  COLLATE Latin1_General_CS_AS)            
  --set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'''', '')             
  --set @sir =  replace(@sir COLLATE Latin1_General_CS_AS,'`', '')             
        
              
  return @sir             
END 
