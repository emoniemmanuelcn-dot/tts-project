const { S3Client, ListObjectsV2Command, DeleteObjectsCommand } = require('@aws-sdk/client-s3');
const fetch = require('node-fetch');
const s3 = new S3Client({ region: process.env.AWS_REGION || 'us-east-1' });

exports.handler = async function(event){
  const bucket = process.env.AUDIO_S3_BUCKET;
  const prefix = process.env.AUDIO_S3_PREFIX || 'tts/';
  const retentionDays = parseInt(process.env.RETENTION_DAYS || process.env.RETENTION_DAYS || '30', 10);
  const cutoff = Date.now() - retentionDays*24*60*60*1000;
  let continuationToken;
  const deleted = [];
  do{
    const list = await s3.send(new ListObjectsV2Command({ Bucket: bucket, Prefix: prefix, ContinuationToken: continuationToken }));
    const toDelete = [];
    (list.Contents||[]).forEach(obj=>{
      if(new Date(obj.LastModified).getTime() < cutoff){ toDelete.push({ Key: obj.Key }); }
    });
    if(toDelete.length){
      const resp = await s3.send(new DeleteObjectsCommand({ Bucket: bucket, Delete: { Objects: toDelete } }));
      (resp.Deleted||[]).forEach(d=> deleted.push(d.Key));
    }
    continuationToken = list.IsTruncated ? list.NextContinuationToken : null;
  }while(continuationToken);
  if(process.env.CLEANUP_NOTIFY_URL && process.env.CLEANUP_NOTIFY_SECRET){
    await fetch(process.env.CLEANUP_NOTIFY_URL, { method:'POST', headers:{ 'Content-Type':'application/json','x-cleanup-secret': process.env.CLEANUP_NOTIFY_SECRET }, body: JSON.stringify({ deleted }) });
  }
  return { deletedCount: deleted.length };
};
