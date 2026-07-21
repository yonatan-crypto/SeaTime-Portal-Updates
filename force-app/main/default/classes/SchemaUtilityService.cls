public with sharing class SchemaUtilityService {

	private static Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();

	public SchemaUtilityService(){}
	
   /* SEAT-36: send map of label and apiName for picklist or other field types
	*
	* @author	: Shira Hai
	* @date		: 22/11/17
	*
	* @method 	getLabelOfField
	* @param 	{String}	: apiObjName
	* @param 	{String}	: apiFieldName
	* @return	{map <String, String>}	: getLabelOfField
	* @static
	*/
    public static map <String, String> getFieldLabelMap(String apiObjName, String apiFieldName){
    	Map <String, String> fieldHebNameMap = New Map <String, String>();
    	//verify apiFieldName field of apiObjName
		Schema.SObjectType sobjectType = schemaMap.get(apiObjName);
		if(sobjectType == null){ return null; }
		Map<String, Schema.SObjectField> fieldMap = sobjectType.getDescribe().fields.getMap();
		if (!fieldMap.containsKey(apiFieldName)) { return null; }
		
		//get field type
		Schema.SObjectField field = fieldMap.get(apiFieldName);
		Schema.DisplayType fldType = field.getDescribe().getType();
		//if is picklist
		if(fldType ==  Schema.DisplayType.Picklist){
			List<Schema.PicklistEntry> plList = field.getDescribe().getPicklistValues();    	
	    	for( Schema.PicklistEntry plVal : plList){
		      fieldHebNameMap.put(plVal.getValue(), plVal.getLabel() );
	   		}  
		} else {
			fieldHebNameMap.put(apiFieldName, field.getDescribe().getlabel());
		}
    	return fieldHebNameMap;
    }
}