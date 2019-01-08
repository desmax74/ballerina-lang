/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */
package org.ballerinalang.util.codegen;

import org.ballerinalang.model.NativeCallableUnit;
import org.ballerinalang.model.types.BFunctionType;
import org.ballerinalang.model.types.BType;
import org.ballerinalang.model.types.TypeTags;
import org.ballerinalang.util.codegen.attributes.AnnotationAttributeInfo;
import org.ballerinalang.util.codegen.attributes.AttributeInfo;
import org.ballerinalang.util.codegen.attributes.AttributeInfoPool;
import org.ballerinalang.util.codegen.cpentries.WorkerInfoPool;
import org.ballerinalang.util.program.WorkerDataIndex;

import java.util.HashMap;
import java.util.Map;

/**
 * {@code CallableUnitInfo} contains common metadata of a Ballerina function/resource/action in the program file.
 *
 * @since 0.87
 */
public class CallableUnitInfo implements AttributeInfoPool, WorkerInfoPool {

    protected String pkgPath;
    protected String name;
    public boolean isNative;
    private boolean isPublic;
    public int flags;

    // Index to the PackageCPEntry
    protected int pkgCPIndex;
    protected int nameCPIndex;

    public BType[] paramTypes;
    protected BType[] retParamTypes;

    protected int signatureCPIndex;

    public int attachedToTypeCPIndex;
    public BType attachedToType;
    public BFunctionType funcType;
    public ChannelDetails[] workerSendInChannels;

    protected Map<AttributeInfo.Kind, AttributeInfo> attributeInfoMap = new HashMap<>();
    
    // Key - data channel name
    private Map<String, WorkerDataChannelInfo> dataChannelInfoMap = new HashMap<>();

    public PackageInfo packageInfo;
    public WorkerInfo defaultWorkerInfo;
    protected Map<String, WorkerInfo> workerInfoMap = new HashMap<>();
    
    public WorkerDataIndex paramWorkerIndex;
    public WorkerDataIndex retWorkerIndex;
    
    private NativeCallableUnit nativeCallableUnit;
    
    private WorkerSet workerSet = new WorkerSet();
    
    private boolean hasReturnType;

    private WorkerDataIndex calculateWorkerDataIndex(BType[] retTypes) {
        WorkerDataIndex index = new WorkerDataIndex();
        index.retRegs = new int[retTypes.length];
        for (int i = 0; i < retTypes.length; i++) {
            BType retType = retTypes[i];
            switch (retType.getTag()) {
                case TypeTags.INT_TAG:
                    index.retRegs[i] = index.longRegCount++;
                    break;
                case TypeTags.BYTE_TAG:
                    index.retRegs[i] = index.intRegCount++;
                    break;
                case TypeTags.FLOAT_TAG:
                    index.retRegs[i] = index.doubleRegCount++;
                    break;
                case TypeTags.STRING_TAG:
                    index.retRegs[i] = index.stringRegCount++;
                    break;
                case TypeTags.BOOLEAN_TAG:
                    index.retRegs[i] = index.intRegCount++;
                    break;
                default:
                    index.retRegs[i] = index.refRegCount++;
                    break;
            }
        }
        return index;
    }
    
    public String getName() {
        return name;
    }

    public String getPkgPath() {
        return pkgPath;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getPackageCPIndex() {
        return pkgCPIndex;
    }

    public PackageInfo getPackageInfo() {
        return packageInfo;
    }

    public int getNameCPIndex() {
        return nameCPIndex;
    }

    public void setNameCPIndex(int nameCPIndex) {
        this.nameCPIndex = nameCPIndex;
    }

    public void setPackageInfo(PackageInfo packageInfo) {
        this.packageInfo = packageInfo;
    }

    public void setNative(boolean aNative) {
        isNative = aNative;
    }

    public boolean isPublic() {
        return isPublic;
    }

    public void setPublic(boolean isPublic) {
        this.isPublic = isPublic;
    }

    public BType[] getParamTypes() {
        return paramTypes;
    }

    public void setParamTypes(BType[] paramTypes) {
        this.paramTypes = paramTypes;
        this.paramWorkerIndex = this.calculateWorkerDataIndex(this.paramTypes);
    }

    public BType[] getRetParamTypes() {
        return retParamTypes;
    }

    public void setRetParamTypes(BType[] retParamType) {
        this.retParamTypes = retParamType;
        this.retWorkerIndex = this.calculateWorkerDataIndex(this.retParamTypes);
        this.hasReturnType = this.retParamTypes != null && this.retParamTypes.length > 0;
    }

    public boolean hasReturnType() {
        return hasReturnType;
    }

    public void setDefaultWorkerInfo(WorkerInfo defaultWorkerInfo) {
        this.defaultWorkerInfo = defaultWorkerInfo;
        this.populateWorkerSet();
    }

    public WorkerInfo getWorkerInfo(String workerName) {
        return workerInfoMap.get(workerName);
    }

    public void addWorkerInfo(String workerName, WorkerInfo workerInfo) {
        workerInfoMap.put(workerName, workerInfo);
        this.populateWorkerSet();
    }

    public Map<String, WorkerInfo> getWorkerInfoMap() {
        return workerInfoMap;
    }
    
    private void populateWorkerSet() {
        this.workerSet.generalWorkers = this.workerInfoMap.values().toArray(new WorkerInfo[0]);
        if (this.workerSet.generalWorkers.length == 0) {
            this.workerSet.generalWorkers = new WorkerInfo[] { this.defaultWorkerInfo };
        } else {
            this.workerSet.initWorker = this.defaultWorkerInfo;
        }
    }
    
    public WorkerSet getWorkerSet() {
        return workerSet;
    }

    @Override
    public AttributeInfo getAttributeInfo(AttributeInfo.Kind attributeKind) {
        return attributeInfoMap.get(attributeKind);
    }

    @Override
    public void addAttributeInfo(AttributeInfo.Kind attributeKind, AttributeInfo attributeInfo) {
        attributeInfoMap.put(attributeKind, attributeInfo);
    }

    @Override
    public AttributeInfo[] getAttributeInfoEntries() {
        return attributeInfoMap.values().toArray(new AttributeInfo[0]);
    }

    @Deprecated
    public AnnAttachmentInfo getAnnotationAttachmentInfo(String packageName, String annotationName) {
        AnnotationAttributeInfo attributeInfo = (AnnotationAttributeInfo) getAttributeInfo(
                AttributeInfo.Kind.ANNOTATIONS_ATTRIBUTE);
        if (attributeInfo == null || packageName == null || annotationName == null) {
            return null;
        }
        for (AnnAttachmentInfo annotationInfo : attributeInfo.getAttachmentInfoEntries()) {
            if (packageName.equals(annotationInfo.getPkgPath()) && annotationName.equals(annotationInfo.getName())) {
                return annotationInfo;
            }
        }
        return null;
    }

    @Override
    public void addWorkerDataChannelInfo(WorkerDataChannelInfo workerDataChannelInfo) {
        dataChannelInfoMap.put(workerDataChannelInfo.getChannelName(), workerDataChannelInfo);
    }

    @Override
    public WorkerDataChannelInfo getWorkerDataChannelInfo(String name) {
        return dataChannelInfoMap.get(name);
    }

    @Override
    public WorkerDataChannelInfo[] getWorkerDataChannelInfo() {
        return dataChannelInfoMap.values().toArray(new WorkerDataChannelInfo[0]);
    }
    
    public NativeCallableUnit getNativeCallableUnit() {
        return nativeCallableUnit;
    }
    
    public void setNativeCallableUnit(NativeCallableUnit nativeCallableUnit) {
        this.nativeCallableUnit = nativeCallableUnit;
    }
    
    /**
     * This represents a worker set with different execution roles.
     */
    public static class WorkerSet {

        public WorkerInfo initWorker;

        public WorkerInfo[] generalWorkers;

    }

    /**
     * Channel details which has channel name and where it resides.
     */
    public static class ChannelDetails {
        public String name;
        public boolean channelInSameStrand;
        public boolean send;

        public ChannelDetails(String name, boolean channelInSameStrand, boolean send) {
            this.name = name;
            this.channelInSameStrand = channelInSameStrand;
            this.send = send;
        }

        @Override
        public String toString() {
            return name;
        }
    }
    
}
